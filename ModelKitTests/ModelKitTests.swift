//
//  ModelKitTests.swift
//  ModelKitTests
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest
@testable import ModelKit

fileprivate class Entity: Model {
    let id = Field<Identifier>()
    
    override var identifierField: FieldType? {
        return self.id
    }
}

fileprivate class Thing: Model {
    let id = Field<Identifier>()
    
    override var identifierField: FieldType? {
        return self.id
    }
}

class ModelKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRouting() {
        let router = RESTRouter()
        
        let thing = Thing()
        XCTAssertNil(router.path(for: thing))

        thing.id.value = "1"
        
        XCTAssertEqual(router.path(for: Thing.self), "things")
        XCTAssertEqual(router.path(for: thing), "things/1")
        
        router.route(Thing.self, to: "objects")
        
        XCTAssertEqual(router.path(for: Thing.self), "objects")
        XCTAssertEqual(router.path(for: thing), "objects/1")
    }
    
}
