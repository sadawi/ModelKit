//
//  File.swift
//  Pods
//
//  Created by Sam Williams on 11/25/15.
//
//

import Foundation

open class Field<T:Equatable>: BaseField<T> {
    open var domain: ValueDomain<T> = ValueDomain()
    
    public required override init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    open override func isChange(oldValue: T?, newValue: T?) -> Bool {
        return oldValue != self.value
    }
    
    open func arrayField(value: [T]?=[], name: String?=nil, priority: Int?=nil, key: String?=nil) -> ArrayField<T> {
        return ArrayField(self, value: value, name: name, priority: priority, key: key)
    }

    open func copy() -> Field<T> {
        let copy = type(of: self).init(value: self.value, name: self.name, priority: self.priority, key: self.key)
        return copy
    }

}
