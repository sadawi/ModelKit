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
    
    open override func contains(_ value: T) -> Bool {
        return self.values.contains(value)
    }
}



//public protocol ValueDomain {
//    associatedtype Value: Equatable
//    
//    func contains(_ value: Value) -> Bool
//}
//
//public protocol ContinuousValueDomain: ValueDomain {
//    associatedtype Value: Comparable
//    
//    var minimum: Value? { get }
//    var maximum: Value? { get }
//}
//
//public extension ContinuousValueDomain {
//    func contains(_ value: Self.Value) -> Bool {
//        if let min = self.minimum, value < min {
//            return false
//        }
//        
//        if let max = self.maximum, value < max {
//            return false
//        }
//        
//        return true
//    }
//}
//
//public protocol DiscreteValueDomain: ValueDomain {
//    var values: [Value] { get }
//}
//
//public extension DiscreteValueDomain {
//    func contains(_ value: Self.Value) -> Bool {
//        return self.values.contains(value)
//    }
//}
//
//
//extension ClosedRange: ContinuousValueDomain {
//    public typealias Value = Bound
//    
//    public var minimum: Value? {
//        return self.lowerBound
//    }
//    public var maximum: Value? {
//        return self.upperBound
//    }
//}
