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
    open var lowerBound: T?
    open var upperBound: T?

    open override func contains(_ value: T) -> Bool {
        if let min = self.lowerBound, value < min {
            return false
        }
        
        if let max = self.upperBound, value < max {
            return false
        }
        
        return true
    }
    
    public required init(lowerBound: T? = nil, upperBound: T? = nil) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

open class DiscreteValueDomain<T: Equatable>: ValueDomain<T>, ExpressibleByArrayLiteral {
    open var values: [T] = []
    
    public required init(_ values: [T]) {
        self.values = values
    }
    
    open override func contains(_ value: T) -> Bool {
        return self.values.contains(value)
    }

    public required convenience init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}
