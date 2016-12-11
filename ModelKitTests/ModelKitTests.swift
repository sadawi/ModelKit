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

fileprivate class Group: Model {
    let id          = Field<Identifier>()
    let entities    = ModelField<Entity>(key: "contents")*

    override var identifierField: FieldType? {
        return self.id
    }
}

fileprivate class Entity: Model, HasOwnerField {
    let id          = Field<Identifier>()
    let possessions = ModelField<Possession>()*
    let group       = ModelField<Group>(inverse: { $0.entities })
    
    override var identifierField: FieldType? {
        return self.id
    }
    
    var ownerField: ModelFieldType? {
        return self.group
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
        XCTAssertNil(router.path(to: thing))

        thing.id.value = "1"
        
        XCTAssertEqual(router.path(to: Thing.self), "things")
        XCTAssertEqual(router.path(to: thing), "things/1")
        
        router.route(Thing.self, to: "objects")
        
        XCTAssertEqual(router.path(to: Thing.self), "objects")
        XCTAssertEqual(router.path(to: thing), "objects/1")
        
        router.unroute(Thing.self)
        
        XCTAssertEqual(router.path(to: Thing.self), "things")
        
        // Nested paths
        
        let entity = Entity()
        entity.id.value = "e1"
        
        thing.entities.value = [entity]
        
        XCTAssertEqual(router.path(to: entity, in: thing.entities), "things/1/relatives/e1")
        XCTAssertEqual(router.path(to: thing.entities), "things/1/relatives")
    }
    
    func testOwnerRouting() {
        let router = RESTRouter()

        let entity = Entity()
        entity.id.value = "e1"
        
        let hat = Possession()
        hat.identifier = "p1"
        hat.entity.value = entity
        
        let group = Group()
        group.identifier = "g1"
        entity.group.value = group
        XCTAssertEqual(router.instancePath(for: hat, maxDepth: 0), "possessions/p1")
        XCTAssertEqual(router.instancePath(for: hat, maxDepth: 1), "entities/e1/possessions/p1")
        
         // Note that this uses the field key "contents" rather than "entities"
        XCTAssertEqual(router.instancePath(for: hat, maxDepth: 2), "groups/g1/contents/e1/possessions/p1")
    }
}

extension ModelKitTests {
    func testFieldPaths() {
        let prefix = FieldPath(["one", "two", "*"])
        XCTAssert(prefix.isPrefix)
        XCTAssertEqual(prefix.components, ["one", "two"])
        
        let a = FieldPath(["one", "two"])
        let b = FieldPath(["one"])
        let c = FieldPath()
        
        XCTAssertFalse(a.isPrefix(of: b))
        XCTAssertTrue(b.isPrefix(of: a))
        
        XCTAssertFalse(a.isPrefix(of: c))
        XCTAssertTrue(c.isPrefix(of: a))
        XCTAssertTrue(c.isPrefix(of: b))
        
        let d:FieldPath = ["one"]
        XCTAssertEqual(d.components, ["one"])
        
        let e = FieldPath(["one"], isPrefix: false)
        XCTAssertFalse(e.matches(a))
        
        // TODO: prefixes might be wrong! If I'm observing geometry/corner/left and I set a whole new geometry, it should be triggered!

    }
}


extension ModelKitTests {
    func testModelObservers() {
        
    }
}
