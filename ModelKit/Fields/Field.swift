//
//  File.swift
//  Pods
//
//  Created by Sam Williams on 11/25/15.
//
//

import Foundation

open class Field<T:Equatable>: BaseField<T> {
    public required override init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    open override func valueUpdated(oldValue:T?, newValue: T?) {
        super.valueUpdated(oldValue: oldValue, newValue: newValue)
        if oldValue != self.value {
            self.valueChanged()
        }
    }
    
    open func arrayField() -> ArrayField<T> {
        return ArrayField(self)
    }

    open func copy() -> Field<T> {
        let copy = type(of: self).init(value: self.value, name: self.name, priority: self.priority, key: self.key)
        return copy
    }

}
