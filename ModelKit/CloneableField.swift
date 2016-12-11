//
//  ClonableField.swift
//  ModelKit
//
//  Created by Sam Williams on 12/10/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

open class CloneableField<T: Equatable>: Field<T>, Cloneable {
    public typealias CloneType = Field<T>
    
    public var prototype: CloneType?
   
    public var clones = NSHashTable<CloneType>()
    
    open func clone() -> Field<T> {
        return self
    }
    
    required public init(value: T?=nil, name: String?=nil, priority: Int=0, key: String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
}
