//
//  ValueTransformerContext.swift
//  ModelKit
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation
import StringInflections

/**
 An object that identifies a particular system of transformations. For example, there might be one context for writing to a JSON API,
 and another for writing user-readable strings.
 */
open class ValueTransformerContext {
    public var name: String
    
    /**
     The casing style (e.g., camelCase or snake_case) for field keys.
     */
    public var keyCase: StringCase? = nil
    
    /**
     Whether nil values should be serialized as NSNull. Note that if this is false, dictionary.keys will not include those with nil values.
     */
    public var explicitNull = false
    
    public init(name: String) {
        self.name = name
    }
    
    private var valueTransformers = TypeDictionary<ValueTransformerType>()
    
    public func transformer<T>(for valueType: T.Type) -> ValueTransformer<T>? {
        return self.valueTransformers[valueType] as? ValueTransformer<T>
    }
    
    public func transform<T>(_ valueType: T.Type, with transformer: ValueTransformer<T>) {
        self.valueTransformers[valueType] = transformer
    }
}

public extension ValueTransformerContext {
    static let defaultContext: ValueTransformerContext = {
        let context = ValueTransformerContext(name: "default")
        context.transform(Float.self, with: NumericValueTransformer<Float>())
        context.transform(Double.self, with: NumericValueTransformer<Double>())
        context.transform(Int.self, with: NumericValueTransformer<Int>())
        return context
    }()
}
