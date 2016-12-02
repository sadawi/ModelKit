//
//  ArrayField.swift
//  Pods
//
//  Created by Sam Williams on 1/7/16.
//
//

import Foundation

/**
 A transformer that reads and writes an array of values.
 */
open class ArrayValueTransformer<T>: ValueTransformer<[T]> {
    public var innerTransformer: ValueTransformer<T> = SimpleValueTransformer()
    
    public convenience init(innerTransformer: ValueTransformer<T>) {
        self.init()
        self.innerTransformer = innerTransformer
    }
    
    public required init() {
        super.init()
    }
    
    open override func importValue(_ value: AnyObject?) -> [T]? {
        if let arrayValue = self.arrayValue(value) {
            return arrayValue.map { self.innerTransformer.importValue($0) }.flatMap{$0}
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value: [T]?, explicitNull: Bool) -> AnyObject? {
        if let value = value {
            return value.map { self.innerTransformer.exportValue($0) }.flatMap { $0 } as AnyObject?
        } else {
            return nil
        }
    }
    
    /**
     Attempts to convert a raw value to an array. This implementation just performs a cast, but you could override to do something else (e.g., split a string, take values from a dictionary, etc.)
     */
    open func arrayValue(_ value: AnyObject?) -> [AnyObject]? {
        return value as? [AnyObject]
    }
}

postfix operator *

/**
 Convenient postfix operator for declaring an ArrayField: just put a * after the declaration for the equivalent single-valued field.
 
 let tags = Field<String>()*.require(...)
 */
public postfix func *<T>(right:Field<T>) -> ArrayField<T> {
    return right.arrayField()
}

/**
 
 A multi-valued field.  It's a wrapper for a single-valued field that will handle transformations and validation for individual values.
 
 Attributes that pertain to the top-level array value (e.g., field name, key, etc.) do properly belong to the ArrayField object and can be initialized there,
 but they will default to any values specified in the inner field.
 
 For example, if we defined a field like:
 let tag = Field<String>(name: "Tag")
 
 then the equivalent ArrayField declaration could be any of these:
 let tags = ArrayField(Field<String>(), name: "Tags")
 let tags = ArrayField(Field<String>(name: "Tags"))
 let tags = Field<String>(name: "Tags")*
 
 */
open class ArrayField<T:Equatable>: BaseField<[T]> {
    /**
     A field describing how individual values will be transformed and validated.
     */
    open var field:Field<T>
    
    open override var value:[T]? {
        didSet {
            self.valueUpdated(oldValue: oldValue, newValue: self.value)
        }
    }
    
    public init(_ field:Field<T>, value:[T]?=[], name:String?=nil, priority:Int?=nil, key:String?=nil) {
        self.field = field
        super.init(name: name ?? field.name, priority: priority ?? field.priority, key:key ?? field.key)
        self.value = value
    }
    
    open func append(_ value:T) {
        self.value?.append(value)
        self.valueAdded(value)
    }
    
    open func removeFirst(_ value:T) {
        if let index = self.value?.index(of: value) {
            self.removeAtIndex(index)
        }
    }

    open func removeAtIndex(_ index:Int) {
        let value = self.value?[index]
        self.value?.remove(at: index)
        if let value = value {
            self.valueRemoved(value)
        }
    }
    
    // MARK: - Dictionary values
    
    open override func defaultValueTransformer(in context: ValueTransformerContext) -> ValueTransformer<[T]> {
        let transformer = ArrayValueTransformer<T>()
        if let innerTransformer = self.field.valueTransformer(in: context) {
            transformer.innerTransformer = innerTransformer
        }
        return transformer
    }
    
    open func valueRemoved(_ value: T) {
    }
    
    open func valueAdded(_ value: T) {
    }
}
