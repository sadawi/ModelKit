//
//  PrototypeTests.swift
//  ModelKit
//
//  Created by Sam Williams on 12/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest
import ModelKit

class PrototypeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObservers() {
        let a = CloneableField<String>(key: "message")
        let b = CloneableField<String>(key: "message")
        a --> b
        
        a.value = "a"
        XCTAssertEqual(b.value, "a")
        a.removeObserver(b)
        a.value = "A"
        XCTAssertEqual(b.value, "a")
    }
    
    func testClonableField() {
        let a = CloneableField<String>(key: "message")
        a.value = "hello"
        let b = a.clone()
        XCTAssertNotNil(b.prototype)
        XCTAssertTrue(b.prototype === a)
        
        XCTAssertEqual(b.key, a.key)
        
        XCTAssertEqual(b.value, a.value)
        
        // Value change should propagate to clone
        a.value = "goodbye"
        XCTAssertEqual(b.value, a.value)
        
        // Explicit detach
        b.detach()
        a.value = "hi"
        XCTAssertEqual(b.value, "goodbye")
        
        // Implicit detach when setting value.
        let c = a.clone()
        c.value = "c"
        a.value = "a"
        XCTAssertEqual(c.value, "c")
    }
    
}