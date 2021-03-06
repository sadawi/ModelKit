//
//  ObservationTests.swift
//  MagneticFields
//
//  Created by Sam Williams on 2/12/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import ModelKit

private class Entity {
    let name = Field<String>()
    let size = Field<Int>()
    let tags = Field<String>()*
}

fileprivate class Person: ValueObservable {
    typealias ValueType = String
    
    var value: String? {
        didSet {
            self.notifyObservers()
        }
    }
    var observations = ObservationRegistry<ValueObservation<String>>()
}

fileprivate class View:ValueObserver, ValueObservable {
    var value:String? {
        didSet {
            self.notifyObservers()
        }
    }
    
    // Observer
    func observedValueChanged<ObservableType:ValueObservable>(from oldValue:String?, to newValue: String?, observable: ObservableType?) {
        self.value = newValue
    }
    
    // Observable
    typealias ValueType = String
    var observations = ObservationRegistry<ValueObservation<ValueType>>()
}

class ObservationTests: XCTestCase {
    func testArrayObservation() {
        let entity = Entity()
        
        var changedValue: [String]? = nil
        
        entity.tags.addObserver { oldValue, newValue in
            changedValue = newValue
        }
        entity.tags.value = ["red", "green"]
        
        XCTAssertEqual(changedValue ?? [], ["red", "green"])
        
        entity.tags.append("yellow")
        
        XCTAssertEqual(changedValue ?? [], ["red", "green", "yellow"])
    }
    
    func testValueChangedParameter() {
        let entity = Entity()
        entity.name.value = "Bob"
        
        var changed = false
        entity.name.addObserver(requiresChange: true) { oldValue, newValue in
            changed = true
        }

        var updated = false
        entity.name.addObserver(requiresChange: false) { oldValue, newValue in
            updated = true
        }

        XCTAssertFalse(changed)
        XCTAssertFalse(updated)
        
        entity.name.value = "Bob"

        XCTAssertFalse(changed)
        XCTAssertTrue(updated)

        updated = false
        changed = false
        
        entity.name.value = "Alice"
        
        XCTAssertTrue(changed)
        XCTAssertTrue(updated)
    }
    
    func testObservation() {
        let view = View()
        let entity = Entity()
        entity.name --> view
        entity.name.value = "Alice"
        XCTAssertEqual(view.value, "Alice")
        
        var value:String = "test"
        let o = entity.name --> { value = $1! }
        entity.name.value = "NEW VALUE"
        XCTAssertEqual(value, "NEW VALUE")
        
        // Can add more closure observers without interfering with old ones.
        var value2:String = "another value"
        entity.name --> { value2 = $1! }
        
        entity.name.value = "hello"
        XCTAssertEqual(value2, "hello")
        XCTAssertEqual(value, "hello")
        
        // Reset to demonstrate...
        entity.name.value = "NEW VALUE"

        // To remove the old one, we need to remove it explicitly.
        entity.name.removeObservation(o)

        entity.name.value = "VALUE 2"
        XCTAssertEqual(value2, "VALUE 2")
        XCTAssertEqual(value, "NEW VALUE")
        
        // But the registered observers are still active
        XCTAssertEqual(view.value, "VALUE 2")
        
        // ...until the observers are explicitly unregistered
        entity.name -/-> view
        entity.name.value = "VALUE 3"
        XCTAssertEqual(view.value, "VALUE 2")
    }
    
    func testHeterogeneousBinding() {
        let a = Entity()
        let v = View()
        
        a.name.value = "Title"
        v <--> a.name
        XCTAssertEqual(v.value, "Title")
        a.name.value = "New Title"
        XCTAssertEqual(v.value, "New Title")
        v.value = "New New Title"
        XCTAssertEqual("New New Title", a.name.value)
    }
    
    func testBinding() {
        let a = Entity()
        let b = Entity()
        
        a.name.value = "John"
        b.name.value = "John"
        XCTAssertTrue(a.name.value == b.name.value)
        
        b.name.value = "Bob"
        
        XCTAssertFalse(a.name.value == b.name.value)
        
        XCTAssertNotEqual(a.name.value, b.name.value)
        
        a.name <--> b.name
        
        XCTAssertEqual(a.name.value, "Bob")
        XCTAssertEqual(b.name.value, "Bob")
        
        a.name.value = "Martha"
        
        XCTAssertEqual(a.name.value, b.name.value)
        
        let c = Entity()
        let d = Entity()
        c.name.value = "Alice"
        d.name.value = "Joan"
        
        XCTAssertNotEqual(c.name.value, d.name.value)
        
        c.name <-- d.name
        XCTAssertEqual(c.name.value, d.name.value)
        
        c.name.value = "Kevin"
        XCTAssertNotEqual(c.name.value, d.name.value)
        
        d.name.value = "Rebecca"
        XCTAssertEqual(d.name.value, "Rebecca")
        
        c.name <-- d.name
        d.name.value = "Rebecca"
        XCTAssertEqual(c.name.value, d.name.value)
        
    }
    
    func testObservable() {
        let object = Person()
        let field = Field<String>()
        let secondField = Field<String>()
        
        object.value = "Bob"
        XCTAssertNotEqual(object.value, field.value)
        
        object --> field
        object --> secondField
        
        object.value = "Alice"
        XCTAssertEqual(object.value, field.value)
        XCTAssertEqual(object.value, secondField.value)
        
        object -/-> field
        object.value = "Phil"
        XCTAssertNotEqual(object.value, field.value)
        XCTAssertEqual(object.value, secondField.value)
    }
    
    func testChaining() {
        let a = Entity()
        let b = Entity()
        
        let observation = a.name --> b.name
        a.name.value = "Wayne"
        
        XCTAssertEqual(a.name.value, b.name.value)
        XCTAssertEqual(a.name.value, observation.value)
        
        let c = Entity()
        observation --> c.name
        
        XCTAssertEqual(a.name.value, c.name.value)
        
        a.name.value = "John"
        XCTAssertEqual("John", c.name.value)
    }
    
    func testChainingInline() {
        let a = Entity()
        let b = Entity()
        let c = Entity()
        let d = Entity()
        
        a.name --> b.name --> c.name --> d.name
        a.name.value = "John"
        
        XCTAssertEqual(a.name.value, b.name.value)
        XCTAssertEqual(a.name.value, c.name.value)
        XCTAssertEqual(a.name.value, d.name.value)
        
        c.name.value = "Alice"
        XCTAssertEqual(a.name.value, "John")
        XCTAssertEqual(d.name.value, "Alice")
    }
    
    func testChainingClosureWithSideEffect() {
        let a = Entity()
        let b = Entity()
        
        var output:String? = nil
        
        a.name --> b.name --> { oldValue, newValue in
            output = newValue
        }
        
        a.name.value = "Joe"
        XCTAssertEqual("Joe", output)
    }


}
