//
//  Clonable.swift
//  ModelKit
//
//  Created by Sam Williams on 12/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol Cloneable {
    associatedtype CloneType: AnyObject
    
    var clones: NSHashTable<CloneType> { get }
    var prototype: CloneType? { get }
    
    func clone() -> CloneType
}

//public extension Clonable {
//    public func registerClone(clone: CloneType) {
//        if let object = clone as? AnyObject {
//            self.clones.addObject(object)
//        }
//    }
//    
//    public func unregisterClone(clone: CloneType) {
//        if let object = clone as? AnyObject {
//            self.clones.removeObject(object)
//        }
//    }
//    
//}
