//
//  ArchiveTests.swift
//  APIKit
//
//  Created by Sam Williams on 2/13/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest
import ModelKit

private class Pet: Model {
    let id = Field<String>()
    let name = Field<String>()
    let owner = ModelField<Person>(key: "ownerID", foreignKey: true)
}

private class Person: Model {
    let id = Field<String>()
    let name = Field<String>()
    
    override var identifierField: FieldType {
        return self.id
    }
}

class ArchiveTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testArchiveRelated() {
        Model.registry = MemoryRegistry()
        
        let archive = ArchiveDataStore.sharedInstance
        let alice = Person.with(identifier: "1234")
        XCTAssertEqual(alice.id.value, "1234")
        
        let alice2 = Person.with(identifier: "1234")
        XCTAssertEqual(alice2, alice)
        
        alice.name.value = "Alice"
        
        let pet = Pet()
        pet.name.value = "Fluffy"
        pet.owner.value = alice
        
        let didLoad = expectation(description: "load")
        let didSave = expectation(description: "save")

        archive.saveList(Pet.self, models: [pet], includeRelated: true).then { () -> () in
            didSave.fulfill()
            
            archive.list(Pet.self).then { pets -> () in
                XCTAssertEqual(pets.count, 1)
                let pet = pets.first!
                XCTAssertEqual(pet.name.value, "Fluffy")
                XCTAssertEqual(pet.owner.value?.name.value, alice.name.value)
                XCTAssertEqual(pet.owner.value, alice)
                
                didLoad.fulfill()
                }.catch { error in
                    XCTFail(String(describing: error))
            }
            }.catch { error in
                XCTFail(String(describing: error))
        }

        self.waitForExpectations(timeout: 1, handler:nil)
    }

    func testArchive() {
        let archive = ArchiveDataStore.sharedInstance
        let person1 = Person()
        person1.name.value = "Alice"
        
        let didLoad = expectation(description: "load")
        let didSave = expectation(description: "save")
        let didDelete = expectation(description: "delete")
        
        archive.saveList(Person.self, models: [person1]).then { () -> () in
            didSave.fulfill()
            
            archive.list(Person.self).then { people -> () in
                XCTAssertEqual(people.count, 1)
                
                let person = people.first!
                XCTAssertEqual(person.name.value, "Alice")
                
                didLoad.fulfill()
                
                archive.deleteAll(Person.self).then {
                    archive.list(Person.self).then { people -> () in
                        XCTAssertEqual(people.count, 0)
                        didDelete.fulfill()
                    }
                }
                
                }.catch { error in
                    XCTFail(String(describing: error))
            }
            }.catch { error in
                XCTFail(String(describing: error))
        }
        
        self.waitForExpectations(timeout: 1, handler:nil)
    }
    
    func testArchiveDeleteAll() {
        let archive = ArchiveDataStore.sharedInstance
        let person1 = Person()
        person1.name.value = "Alice"
        
        let didDelete = expectation(description: "delete")
        
        archive.saveList(Person.self, models: [person1]).then { () -> () in
            archive.deleteAll(Person.self).then {
                archive.list(Person.self).then { people -> () in
                    XCTAssertEqual(people.count, 0)
                    didDelete.fulfill()
                }
            }
        }
        
        self.waitForExpectations(timeout: 1, handler:nil)
    }

}
