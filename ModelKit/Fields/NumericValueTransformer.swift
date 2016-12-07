//
//  NumericValueTransformer.swift
//  ModelKit
//
//  Created by Sam Williams on 12/7/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol FloatConvertible {
    var floatValue: Float   { get }
}

public protocol DoubleConvertible {
    var doubleValue: Double { get }
}

public protocol IntConvertible {
    var intValue: Int       { get }
}

public protocol NumericConvertible: FloatConvertible, DoubleConvertible, IntConvertible {
}

public extension NumericConvertible {
    func coerced<T>() -> T? {
        if T.self == Float.self         { return self.floatValue as? T }
        else if T.self == Double.self   { return self.doubleValue as? T }
        else if T.self == Int.self      { return self.intValue as? T }
        else                            { return nil }
    }
}

extension Float: NumericConvertible {
    public var floatValue: Float { return self }
    public var doubleValue: Double { return Double(self) }
    public var intValue: Int { return Int(self) }
}

extension Double: NumericConvertible {
    public var floatValue: Float { return Float(self) }
    public var doubleValue: Double { return self }
    public var intValue: Int { return Int(self) }
}

extension Int: NumericConvertible {
    public var floatValue: Float { return Float(self) }
    public var doubleValue: Double { return Double(self) }
    public var intValue: Int { return self }
}

extension NSNumber: NumericConvertible {
}

open class NumericValueTransformer<T: NumericConvertible>: SimpleValueTransformer<T> {
    open override func importValue(_ value: Any?, in context: ValueTransformerContext = .defaultContext) -> T? {
        if let convertible = value as? NumericConvertible {
            return convertible.coerced()
        }
        return nil
    }
}
