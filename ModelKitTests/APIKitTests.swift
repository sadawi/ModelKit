//
//  APIKitTests.swift
//  APIKitTests
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import XCTest
import PromiseKit

@testable import ModelKit

private class BaseModel:Model {
    let id          = Field<String>()
    override var identifierField:FieldType {
        return self.id
    }
}

private class Category:BaseModel {
    let categoryName = Field<String>()
}

private class Product:BaseModel {
    let productName = Field<String>()
    let category = ModelField<Category>()
}

private class Company:BaseModel {
    let name        = Field<String>()
    let products    = ModelField<Product>()*
    let widgets     = ModelField<Product>(key: "widgetIDs", foreignKey: true)*
}

private class Person:BaseModel {
    let name    = Field<String>()
    let age     = Field<Int>()
    let company = ModelField<Company>(foreignKey: true)
    // TODO: pets (avoid cycles!)
    
    required init() { }
    
    init(name:String?, age:Int?) {
        self.name.value = name
        self.age.value = age
    }
}

private class Pet:BaseModel {
    let name    = Field<String>()
    let species = Field<String>()
    let owner   = ModelField<Person>(foreignKey: true)
    
    required init() { }

    init(name:String?, species:String?) {
        self.name.value = name
        self.species.value = species
    }
}

private class Left: Model {
    let id = Field<String>()
    let right = ModelField<Right>()
}

private class Right: Model {
    let id = Field<String>()
    let left = ModelField<Left>()
}

class APIKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let store = MemoryModelStore()

        ModelManager.sharedInstance.modelStore = store
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testArrayVisit() {
        let company = Company.from(dictionaryValue: ["products": [["id":"100", "productName": "iPhone"]]])
        XCTAssertEqual(company?.products.value?.count, 1)
        var iphone = false
        company?.visitAllFieldValues(recursive: true) { value in
            if (value as? String) == "iPhone" {
                iphone = true
            }
        }
        XCTAssert(iphone)
    }
    
    func testCycles() {
        let left = Left()
        let right = Right()
        
        left.id.value = "leftID"
        right.id.value = "rightID"
        
        left.right.value = right
        right.left.value = left
        
        let leftDict = left.dictionaryValue()
        XCTAssertEqual(leftDict.count, 2)
        
        XCTAssertEqual(leftDict["id"] as? String, "leftID")

        let leftRightDict = leftDict["right"] as? AttributeDictionary
        XCTAssertEqual(leftRightDict?["id"] as? String, "rightID")
        
        let leftRightLeftDict = leftRightDict?["left"] as? AttributeDictionary
        // Should only have the identifier
        XCTAssertEqual(leftRightLeftDict?.count, 1)
        XCTAssertNil(leftRightLeftDict?["left"])
        XCTAssertNil(leftRightLeftDict?["right"])
        XCTAssertEqual(leftRightLeftDict?["id"] as? String, "leftID")
        
        var fields:[FieldType] = []
        left.visitAllFields { field in
            fields.append(field)
        }
        XCTAssertEqual(fields.count, 4)

        var fieldValues:[Any?] = []
        left.visitAllFieldValues { value in
            fieldValues.append(value)
        }
        XCTAssertEqual(fieldValues.count, 4)
    
    }
    
    func testArrayShells() {
        let company = Company.from(dictionaryValue: ["widgetIDs": ["44", "55"]])
        let shells = company?.incompleteChildModels(recursive: true)
        XCTAssertEqual(shells?.count, 2)
    }

    func testShells() {
        let didSave = expectation(description: "save")
        
        let phil = Person.from(dictionaryValue: ["name": "Phil", "age": 44, "company": "testID"])!
        
        _ = ModelManager.sharedInstance.modelStore.save(phil).then { model -> Void in
            // Fails because 555 is not a valid owner id (should be string)
            let grazi0 = Pet.from(dictionaryValue: ["name": "Grazi", "owner": 555])
            XCTAssertNil(grazi0?.owner.value?.id.value)

            let grazi1 = Pet.from(dictionaryValue: ["name": "Grazi", "owner": phil.id.value!])
            XCTAssertEqual(grazi1?.owner.value?.id.value, phil.id.value)
            
            let shells = grazi1!.incompleteChildModels()
            XCTAssertEqual(1, shells.count)
            let shell = shells.first as? Person
            XCTAssertEqual(shell?.identifier, phil.identifier)
            
            let grazi2 = Pet()
            grazi2.owner.value = phil
            let shells2 = grazi2.incompleteChildModels(recursive: true)
            XCTAssertEqual(1, shells2.count)
            let shell2 = shells2.first as? Company
            XCTAssertNotNil(shell2)
            
            didSave.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler:nil)
    }
    
    func testUnloading() {
        let product = Product()
        product.productName.value = "iPhone"
        
        let company = Company()
        company.identifier = "1111"
        company.name.value = "Apple"
        company.products.value = [product]
        
        XCTAssertNotNil(company.name.value)
        XCTAssertNotNil(company.products.value)
        
        company.unload()
        XCTAssertNil(company.name.value)
        XCTAssertNil(company.products.value)
        XCTAssertNotNil(company.identifier)
    }
    
    func testResource() {
        let didSave = expectation(description: "save")
        let didLookup = expectation(description: "lookup")
        
        let a = Person(name: "Kevin", age: 33)
        XCTAssertNil(a.identifier)
        
        _ = ModelManager.sharedInstance.modelStore.save(a).then { model -> Promise<Person> in
            XCTAssertNotNil(model.identifier)
            didSave.fulfill()
            let id = model.identifier!
            return ModelManager.sharedInstance.modelStore.read(type(of: a), identifier: id)
            }.then { model -> () in
                XCTAssertNotNil(model)
                XCTAssert(model === a)
                didLookup.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler:nil)
    }

    func testVisitAllFields() {
        let company = Company()
        company.name.value = "Apple"
        
        let iphone = Product()
        iphone.productName.value = "iPhone"
        company.products.value = [iphone]
        
        var keys:[String] = []
        
        company.visitAllFields(recursive: false) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sorted(), ["id", "name", "products", "widgetIDs"])
        
        keys = []
        company.visitAllFields(recursive: true) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sorted(), ["category", "id", "id", "name", "productName", "products", "widgetIDs"])
    }

    func testVisitAllFieldsSimple() {
        let category = Category()
        category.categoryName.value = "phones"
        
        let iphone = Product()
        iphone.productName.value = "iPhone"
        iphone.category.value = category
        
        var keys:[String] = []
        
        category.visitAllFields(recursive: false) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sorted(), ["categoryName", "id"])
        
        keys = []
        iphone.visitAllFields(recursive: true) { field in
            if let k = field.key {
                keys.append(k)
            }
        }
        XCTAssertEqual(keys.sorted(), ["category", "categoryName", "id", "id", "productName"])
    }
    
    func testSaveDelete() {
        let didSave = expectation(description: "save")
        let didList = expectation(description: "list")
        let didDelete = expectation(description: "delete")
        
        let store = MemoryModelStore()
        let a = Person()
        a.identifier = "12324"
        _ = store.save(a).then { _ -> () in
            didSave.fulfill()
            _ = store.list(Person.self).then { people -> () in
                XCTAssertEqual(people.count, 1)
                didList.fulfill()

                _ = store.deleteAll(Person.self).then { () -> () in
                    _ = store.list(Person.self).then { people -> () in
                        XCTAssertEqual(people.count, 0)
                        didDelete.fulfill()
                    }
                }
            }
        }
        
        self.waitForExpectations(timeout: 1, handler:nil)

    }

//    func testSaveDeleteEverything() {
//        let didDeleteB = expectationWithDescription("deleteB")
//        let didDeleteA = expectationWithDescription("deleteA")
//        
//        let store = MemoryModelStore()
//        
//        let a = Person()
//        a.identifier = "123244"
//        
//        let b = Product()
//        b.identifier = "12345566"
//        
//        when(store.save(a), store.save(b)).then { _ -> () in
//            store.list(Person.self).then { people -> () in
//                XCTAssertEqual(people.count, 1)
//                
//                store.deleteAll().then { () -> () in
//                    store.list(Person.self).then { people -> () in
//                        XCTAssertEqual(people.count, 0)
//                        didDeleteA.fulfill()
//                    }
//                    
//                    store.list(Product.self).then { products -> () in
//                        XCTAssertEqual(products.count, 0)
//                        didDeleteB.fulfill()
//                    }
//                }
//            }
//        }
//        
//        self.waitForExpectationsWithTimeout(1, handler:nil)
//        
//    }
}

private class Parent: Model {
    let id = Field<String>()
    let name = Field<String>(value: "parent name")
    let children = ModelField<Child>()*
}

private class Child: Model {
    let id = Field<String>()
    let name = Field<String>(value: "child name")
    let parent = ModelField<Parent>(inverse: { $0.children })
}

extension APIKitTests {
    func testBidirectionalRelationshipSerializationCycles() {
        let parent = Parent()
        parent.id.value = "pid"
        let child = Child()
        child.id.value = "cid"
        
        child.parent.value = parent
        let dict = child.dictionaryValue()
        print(dict)
        XCTAssert(dict.count > 0)
    }
}
