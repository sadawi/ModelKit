//
//  ModelKitTests.swift
//  ModelKitTests
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import XCTest
@testable import ModelKit

fileprivate class Possession: Model, HasOwnerField {
    let id          = Field<Identifier>()
    let entity      = ModelField<Entity>(inverse: { $0.possessions })
    
    override var identifierField: FieldType? {
        return self.id
    }
    
    var ownerField: ModelFieldType? {
        return self.entity
    }
}

fileprivate class Entity: Model {
    let id          = Field<Identifier>()
    let possessions = ModelField<Possession>()*
    
    override var identifierField: FieldType? {
        return self.id
    }
}

fileprivate class Thing: Model {
    let id          = Field<Identifier>()
    let entities    = ModelField<Entity>(key: "relatives")*
    
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
        
        router.unroute(Thing.self)
        
        XCTAssertEqual(router.path(for: Thing.self), "things")
        
        // Nested paths
        
        let entity = Entity()
        entity.id.value = "e1"
        
        thing.entities.value = [entity]
        
        XCTAssertEqual(router.path(for: entity, in: thing.entities), "things/1/relatives/e1")
        XCTAssertEqual(router.path(for: thing.entities), "things/1/relatives")
    }
    
    func testOwnerRouting() {
        let router = RESTRouter()

        let entity = Entity()
        entity.id.value = "e1"
        
        let hat = Possession()
        hat.identifier = "p1"
        hat.entity.value = entity
        
        XCTAssertEqual(router.collectionPath(for: hat), "entities/e1/possessions")
        XCTAssertEqual(router.instancePath(for: hat), "entities/e1/possessions/p1")
    }
    
}
