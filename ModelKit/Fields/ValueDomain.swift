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
    
    /**
     Returns a value ensured to be contained within this domain, or nil.
     */
    open func clamp(_ value: T) -> T? {
        if self.contains(value) {
            return value
        } else {
            return nil
        }
    }
}

public enum RangeContainment {
    case within
    case below
    case above
}

open class RangeValueDomain<T: Comparable>: ValueDomain<T> {
    open var lowerBound: T?
    open var upperBound: T?
    
    public func containment(of value: T) -> RangeContainment {
        if let min = self.lowerBound, value < min {
            return .below
        }
        
        if let max = self.upperBound, value > max {
            return .above
        }
        
        return .within
    }
    
    open override func contains(_ value: T) -> Bool {
        return self.containment(of: value) == .within
    }
    
    public required init(lowerBound: T? = nil, upperBound: T? = nil) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    public convenience init(_ range: ClosedRange<T>) {
        self.init(lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
    
    open override func clamp(_ value: T) -> T? {
        switch self.containment(of: value) {
        case .below: return self.lowerBound
        case .above: return self.upperBound
        case .within: return value
        }
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
