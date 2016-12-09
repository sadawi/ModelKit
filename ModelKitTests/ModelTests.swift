//
//  FieldModelTests.swift
//  APIKit
//
//  Created by Sam Williams on 12/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import XCTest
import ModelKit
import PromiseKit

class ModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    fileprivate class Profile: Model {
        let person:ModelField<Person> = ModelField<Person>(inverse: { $0.profile })
    }
    
    fileprivate class Company: Model {
        let id = Field<Identifier>()
        let name = Field<String>()
        let size = Field<Int>()
        let parentCompany = ModelField<Company>()
        let employees:ModelArrayField<Person> = ModelField<Person>(inverse: { person in return person.company })*
        
        override var identifierField: FieldType? {
            return id
        }
    }
    
    fileprivate class Person: Model {
        let name = Field<String>()
        let company = ModelField<Company>(inverse: { company in return company.employees })
        let profile = ModelField<Profile>(inverse: { $0.person })
    }
    
    fileprivate class Club: Model {
        let name = Field<String>()
        let members = ModelField<Person>()*
    }
    
    func testFieldModel() {
        let co = Company()
        co.name.value = "The Widget Company"
        co.size.value = 22
        
        let fields = co.fields
        XCTAssertNotNil(fields["name"])
        
        let co2 = Company()
        co2.name.value = "Parent Company"
        co.parentCompany.value = co2
        
        let dict = co.dictionaryValue()
        print(dict)
        
        XCTAssertEqual(dict["name"] as? String, "The Widget Company")
        XCTAssertEqual(dict["size"] as? Int, 22)
        let parentDict = dict["parentCompany"]
        XCTAssert(parentDict is AttributeDictionary)
        
        if let parentDict = parentDict as? AttributeDictionary {
            XCTAssertEqual(parentDict["name"] as? String, "Parent Company")
        }
    }
    
    fileprivate class InitializedFields: Model {
        let name = Field<String>()
        
        fileprivate override func initializeField(_ field: FieldType) {
            if field.key == "name" {
                field.name = "Test"
            }
        }
    }
    
    func testArrayFields() {
        let a = Person()
        a.name.value = "Alice"

        let b = Person()
        b.name.value = "Bob"
        
        let c = Club()
        c.name.value = "Chess Club"
        c.members.value = [a,b]
        
        let cDict = c.dictionaryValue()
        XCTAssertEqual(cDict["name"] as? String, "Chess Club")
        
        let members = cDict["members"] as? [AttributeDictionary]
        XCTAssertEqual(members?.count, 2)
        if let first = members?[0] {
            XCTAssertEqual(first["name"] as? String, "Alice")
        } else {
            XCTFail()
        }
    }
    
    func testFieldInitialization() {
        let model = InitializedFields()
        XCTAssertEqual(model.name.name, "Test")
    }
    
    func testSelectiveDictionary() {
        let co = Company()
        co.name.value = "Apple"
        let dictionary = co.dictionaryValue(fields: [co.name])
        XCTAssertEqual(dictionary as! [String: String], ["name": "Apple"])
    }
    
    func testInverseFields() {
        let person1 = Person()
        let profileA = Profile()
        
        person1.profile.value = profileA
        XCTAssertEqual(profileA.person.value, person1)
        
        let profileB = Profile()
        profileB.person.value = person1
        XCTAssertEqual(person1.profile.value, profileB)
        
        XCTAssertNil(profileA.person.value)
        
        let company1 = Company()
        let company2 = Company()

        person1.company.value = company1
        XCTAssertEqual(1, company1.employees.value?.count)
        
        company1.employees.removeFirst(person1)
        XCTAssertEqual(0, company1.employees.value?.count)
        XCTAssertNil(person1.company.value)
        
        company2.employees.value = [person1]
        XCTAssertEqual(person1.company.value, company2)
        XCTAssertEqual(0, company1.employees.value?.count)
    }
    
    fileprivate class Letter: Model {
        override class func instanceClass<T>(for dictionaryValue: AttributeDictionary) -> T.Type? {
            if let letter = dictionaryValue["letter"] as? String {
                if letter == "a" {
                    return A.self as? T.Type
                } else if letter == "b" {
                    return B.self as? T.Type
                } else if letter == "x" {
                    return UnrelatedClass.self as? T.Type
                } else {
                    return nil
                }
            }
            return nil
        }
    }
    
    fileprivate class A: Letter {
    }
    
    fileprivate class B: Letter {
    }
    
    fileprivate class UnrelatedClass: Model {
    }
    
    func testCustomSubclass() {
        let a = Letter.from(dictionaryValue: ["letter": "a"])
        XCTAssert(a is A)

        let b = Letter.from(dictionaryValue: ["letter": "b"])
        XCTAssert(b is B)
        
        // We didn't define the case for "c", so it falls back to Letter.
        let c = Letter.from(dictionaryValue: ["letter": "c"])
        XCTAssert(type(of: c!) == Letter.self)

        // Note that the unrelated type falls back to Letter!
        let x = Letter.from(dictionaryValue: ["letter": "x"])
        XCTAssert(type(of: x!) == Letter.self)
    }
    
    fileprivate class Object: Model {
        let id = Field<String>()
        
        let name                = Field<String>().requireNotNil()
        let component           = ModelField<Component>()
        let essentialComponent  = ModelField<EssentialComponent>().requireValid()
        
        override var identifierField: FieldType? {
            return self.id
        }
    }
    
    fileprivate class EssentialComponent: Model {
        let number = Field<Int>().requireNotNil()
    }
    
    fileprivate class Component: Model {
        let id = Field<String>()

        let name = Field<String>().requireNotNil()
        let age = Field<String>().requireNotNil()

        override var identifierField: FieldType? {
            return self.id
        }
    }
    
    func testNestedValidations() {
        let object = Object()
        let component = Component()
        let essentialComponent = EssentialComponent()
        
        object.component.value = component
        object.essentialComponent.value = essentialComponent
        
        // Object is missing name and a valid EssentialComponent
        XCTAssertTrue(object.validate().isInvalid)
        
        object.name.value = "Widget"

        // Object is still missing a valid EssentialComponent
        XCTAssertFalse(object.validate().isValid)
        
        // Object has a valid EssentialComponent.  Component is still invalid, but that's OK.
        object.essentialComponent.value?.number.value = 1
        
        XCTAssertTrue(object.validate().isValid)
        
        XCTAssert(object.component.value?.validate().isInvalid == true)
    }
    
    func testValidationMessages() {
        let component = EssentialComponent()
        let state = component.validate()
        XCTAssertEqual(state, ValidationState.invalid(["is required"]))
    }
    
//    func testCascadeDelete() {
//        let memory = MemoryModelStore()
//
////        Model.registry = MemoryRegistry(modelStore: memory)
//        let didSave = expectationWithDescription("save")
//        let didDelete = expectationWithDescription("delete")
//        let object = Object()
//        let component = Component()
//        object.component.value = component
//        
//        when(memory.save(object), memory.save(component)).then { _ in
//            memory.list(Object.self).then { objects -> () in
//                XCTAssertEqual(objects.count, 1)
//                }.then {
//                    memory.list(Component.self).then { components -> () in
//                        XCTAssertEqual(components.count, 1)
//                        didSave.fulfill()
//                        }
//
//                }.then {
//                    memory.delete(object).then { _ in
//                        memory.list(Component.self).then { components -> () in
//                            XCTAssertEqual(components.count, 0)
//                            didDelete.fulfill()
//                        }
//                    }
//            }
//        }
//        
//        self.waitForExpectationsWithTimeout(1, handler: nil)
//    }
    
    func testExplicitNulls() {
        let model = Company()
        let parent = Company()
        
        let context = ValueTransformerContext(name: "nulls")
        context.explicitNull = false
        
        model.parentCompany.value = parent
        var d0 = model.dictionaryValue(in: context)
        
        var parentDictionary = d0["parentCompany"] as? AttributeDictionary
        XCTAssertNotNil(parentDictionary)
        XCTAssertNil(parentDictionary?["name"])

        context.explicitNull = true

        d0 = model.dictionaryValue(in: context)
        parentDictionary = d0["parentCompany"] as? AttributeDictionary
        XCTAssertNotNil(parentDictionary?["name"])
        // TODO
//        XCTAssertEqual(parentDictionary?["name"] is NSNull)

        // We haven't set any values, so nothing will be serialized anyway
        let d = model.dictionaryValue(in: context)
        XCTAssert(d["name"] == nil)

        // Now, set a value explicitly, and it should appear in the dictionary
        model.name.value = nil
        let d2 = model.dictionaryValue(in: context)
        XCTAssert(d2["name"] is NSNull)
        
        
    }
    
    func testMerging() {
        let model = Company()
        let model2 = Company()
        
        model.identifier = "1"
        model2.identifier = "2"
        
        model.name.value = "Apple"
        model2.name.value = "Google"
        
        model.merge(from: model2)
        XCTAssertEqual(model.name.value, "Google")
        XCTAssertEqual(model.identifier, "1")

        model.merge(from: model2, includeIdentifier: true)
        XCTAssertEqual(model.identifier, "2")
    }
}
