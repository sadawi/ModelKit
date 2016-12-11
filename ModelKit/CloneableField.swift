//
//  ClonableField.swift
//  ModelKit
//
//  Created by Sam Williams on 12/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

open class CloneableField<T: Equatable>: Field<T>, Cloneable {
    public typealias CloneType = CloneableField<T>

    public var prototype: CloneType? {
        willSet {
            if let prototype = self.prototype {
                prototype -/-> self
            }
        }
        didSet {
            if let prototype = self.prototype {
                prototype --> self
            }
        }
    }

    public var clones = NSHashTable<CloneType>()
    
    open func clone() -> CloneableField<T> {
        let copy = self.copy() as! CloneableField<T>
        copy.prototype = self
        return copy
    }
    
    required public init(value: T?=nil, name: String?=nil, priority: Int=0, key: String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    /**
     Separates from prototype
     */
    public func detach() {
        self.prototype = nil
        // TODO: detach value
    }
}
