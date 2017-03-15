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
    let name        = Field<String>()
    let group       = ModelField<Group>(inverse: { $0.entities })
    let size        = Field<Int>()
    
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
    func testFieldPathKey() {
        let model = Model()
        let key = "name"
        model << Field<String>(key: key)
        model[key] = "Bob"
        XCTAssertEqual(model[key] as? String, "Bob")
    }
    
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
    
    func testInterface() {
        let model = Model()
        let name = Field<String>(priority: 0, key: "name")
        let age = Field<Int>(priority: 1, key: "age")
        let rank = Field<Int>(key: "rank")
        
        model << age
        model << rank
        model << name
        
        XCTAssertEqual(rank.priority, Interface.defaultPriorityOffset)
        
        XCTAssertEqual(model.interface.fields.map{$0.key!}, ["name", "age", "rank"])
        
//        let entity = Entity()
//        
//        // Note: this is assuming that reflection will process fields in the order they're defined in the class.
//        // That's nice to have, but it's not documented, so this test is commented out.
//        XCTAssertEqual(entity.id.priority, Interface.defaultPriorityOffset)
//        XCTAssertEqual(entity.possessions.priority, Interface.defaultPriorityOffset + 1)
//        
//        XCTAssertEqual(entity.interface.fields.map{$0.key!}, ["id", "possessions", "name", "group", "size"])
    }
    
    func testBlankable() {
        let entity = Entity()
        XCTAssert(entity.isBlank)
        entity.name.value = "Test"
        XCTAssertFalse(entity.isBlank)
        
        // Model blankness is recursive: all related models must also be blank or nil.
        let entity2 = Entity()
        let group = Group()
        XCTAssert(group.isBlank)
        entity2.group.value = group
        XCTAssert(entity2.isBlank)
        group.id.value = "1234"
        XCTAssertFalse(entity2.isBlank)
    }
}


extension ModelKitTests {
    func testModelObservers() {
        let m = Model()
        m << Field<String>(key: "name")
        m["name"] = "Bob"
        
        var changedPath: FieldPath? = nil
        m.addObserver { model, path, _ in
            changedPath = path
        }
        m["name"] = "Alice"
        XCTAssertEqual(changedPath?.components ?? [], ["name"])

        let n = Model()
        n << ModelField<Model>(key: "person")
        n << Field<String>(key: "color")
        n["person"] = m
        
        var nChangedPath: FieldPath? = nil
        n.addObserver { model, path, _ in
            nChangedPath = path
        }
        m["name"] = "Joe"
        XCTAssertEqual(nChangedPath?.components ?? [], ["person", "name"])

        
        // Observe only specified paths
        
        var changedPathC: FieldPath? = nil
        
        n.addObserver(for: ["person", "name"]) { model, path, _ in
            changedPathC = path
        }
        n["color"] = "blue"
        XCTAssertEqual(nChangedPath?.components ?? [], ["color"])
        XCTAssertNil(changedPathC)
        
        m["name"] = "Jimmy"
        
        XCTAssertEqual(changedPathC?.components ?? [], ["person", "name"])
        
        // Now replace the parent of the observed path. Should also trigger observation.
        changedPathC = nil
        let person2 = Model()
        n["person"] = person2
        XCTAssertEqual(changedPathC?.components ?? [], ["person"])
    }
}
