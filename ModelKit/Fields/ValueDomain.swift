//
//  ValueDomain.swift
//  ModelKit
//
//  Created by Sam Williams on 3/14/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

open class ValueDomain<T: Equatable> {
    open func contains(_ value: T) -> Bool {
        return true
    }
}

open class ContinuousValueDomain<T: Comparable>: ValueDomain<T> {
    open var minimum: T?
    open var maximum: T?

    open override func contains(_ value: T) -> Bool {
        if let min = self.minimum, value < min {
            return false
        }
        
        if let max = self.maximum, value < max {
            return false
        }
        
        return true
    }
}

open class DiscreteValueDomain<T: Equatable>: ValueDomain<T> {
    open var values: [T] = []
    
    init(_ values: [T]) {
        self.values = values
    }
    
    open override func contains(_ value: T) -> Bool {
        return self.values.contains(value)
    }
}
