//
//  ValidationRule.swift
//  Pods
//
//  Created by Sam Williams on 11/28/15.
//
//

import Foundation

open class ValidationRule<ValueType> {
    var test:((ValueType) -> Bool)?
    var message:String?
    var allowNil:Bool = true
    
    public init() { }
    
    public init(test:@escaping ((ValueType) -> Bool), message:String?=nil, allowNil:Bool = true) {
        self.message = message ?? "is invalid"
        self.test = test
        self.allowNil = allowNil
    }
    
    open func validate(_ value:ValueType?) -> Bool {
        if let unwrappedValue = value {
            return self.validate(unwrappedValue)
        } else {
            return self.allowNil
        }
    }
    
    func validate(_ value:ValueType) -> Bool {
        if let test = self.test {
            return test(value)
        } else {
            return true
        }
    }
}
