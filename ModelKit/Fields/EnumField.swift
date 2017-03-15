//
//  EnumField.swift
//  Pods
//
//  Created by Sam Williams on 12/10/15.
//
//

import Foundation

public protocol Enumerable: RawRepresentable, Equatable {
    static func allValues() -> [Self]
}

/**
 A value transformer that attempts to convert between raw values and enums.
 */
open class EnumValueTransformer<E:Enumerable>: ValueTransformer<E> {
    
    public required init() {
        super.init()
    }
    
    open override func importValue(_ value:Any?, in context: ValueTransformerContext = .defaultContext) -> E? {
        if let raw = value as? E.RawValue {
            return E(rawValue: raw)
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value:E?, in context: ValueTransformerContext = .defaultContext) -> Any? {
        return (value?.rawValue as Any?) ?? type(of: self).nullValue(explicit: context.explicitNull)
    }
}

/**
 A field whose value is Enumerable
 */
open class EnumField<T>: Field<T> where T:Enumerable {
    public required init(value:T?=nil, name:String?=nil, priority:Int? = nil, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
        self.domain = DiscreteValueDomain(T.allValues())
    }
    
    open override func defaultValueTransformer(in context: ValueTransformerContext) -> ValueTransformer<T> {
        return EnumValueTransformer<T>()
    }
}
