//
//  ArrayFieldTests.swift
//  MagneticFields
//
//  Created by Sam Williams on 1/31/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import ModelKit

private class Thing: Equatable {
    var name:String?
}
private func ==(left:Thing, right:Thing) -> Bool {
    return left.name == right.name
}

private class Pet {
    let name        = Field<String>()
    let commands    = Field<String>()*
    let things      = Field<Thing>()*
}

class ArrayFieldTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testArray() {
        let spot = Pet()
        spot.name.value = "Spot"
        spot.commands.value = ["fetch", "roll over"]
        
        XCTAssertEqual(spot.commands.value?.count, 2)
        
        let fido = Pet()
        fido.commands.value?.append("lie down")
        XCTAssertEqual(fido.commands.value?.count, 1)
        
        // Make sure duplicates are still added
        fido.commands.append("lie down")
        XCTAssertEqual(fido.commands.value?.count, 2)
        
        fido.commands.removeAtIndex(0)
        XCTAssertEqual(fido.commands.value?.count, 1)
        
        fido.commands.removeFirst("lie down")
        XCTAssertEqual(fido.commands.value?.count, 0)
    }
    
    func testDefaultTransformers() {
        let raw: AttributeDictionary = ["ages": [1,2,3] as AnyObject]
        let ages = Field<Int>(key: "ages")*
        ages.read(from: raw)
        XCTAssertEqual([1,2,3], ages.value!)
        
        var output: AttributeDictionary = [:]
        ages.write(to: &output)
        
        if let outputAges = output["ages"] {
            if let outputAges = outputAges as? [Int] {
                XCTAssertEqual([1,2,3], outputAges)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }

//    func testCustomTransformers() {
//        let raw: AttributeDictionary = ["ages": [0: 1, 1: 2, 2: 3] as AnyObject]
//        
//        let customTransformer = ModelKit.ValueTransformer<[Int]>(
//            importAction: { (value: AnyObject?) -> [Int]? in
//                if let dictionary = value as? [Int: Int] {
//                    return Array(dictionary.values)
//                }
//                return nil
//            },
//            exportAction: { (value: [Int]?) -> AnyObject? in
//                return nil
//            } )
//        
//        let ages = Field<Int>(key: "ages")*.transform(with: customTransformer)
//        ages.read(from: raw)
//        XCTAssertEqual([1,2,3], ages.value!)
//    }

}
