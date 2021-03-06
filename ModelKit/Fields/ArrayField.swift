//
//  ArrayField.swift
//  Pods
//
//  Created by Sam Williams on 1/7/16.
//
//

import Foundation

public extension Sequence where Iterator.Element: Equatable {
    var uniqueElements: [Iterator.Element] {
        return self.reduce([]) { uniqueElements, element in
            uniqueElements.contains(element)
                ? uniqueElements
                : uniqueElements + [element]
        }
    }
}

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
    
    open override func importValue(_ value: Any?, in context: ValueTransformerContext = .defaultContext) -> [T]? {
        if let arrayValue = self.arrayValue(value) {
            return arrayValue.map { self.innerTransformer.importValue($0, in: context) }.flatMap{$0}
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value: [T]?, in context: ValueTransformerContext = .defaultContext) -> Any? {
        if let value = value {
            let arrayValue = value.map { self.innerTransformer.exportValue($0, in: context) }.flatMap { $0 }
            return self.scalarValue(arrayValue)
        } else {
            return nil
        }
    }
    
    /**
     Attempts to convert a raw value to an array. This implementation just performs a cast, but you could override to do something else (e.g., split a string, take values from a dictionary, etc.)
     */
    open func arrayValue(_ value: Any?) -> [Any]? {
        return value as? [Any]
    }
    
    /**
     Attempts to convert an array to a raw value. This implementation just performs a cast, but you could override to do something else (e.g., join a string, write values to a dictionary, etc.)
     */
    open func scalarValue(_ value: [Any]) -> Any? {
        return value as Any?
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
 A field that wraps another field. That is, it has both its own value (U) and an inner field and value (T).
 U and T may be related by some transformation -- for example, an ArrayField<T> wraps an inner field of type T, and has U = [T].
 */
open class WrapperField<T: Equatable, U>: BaseField<U> {
    /**
     A field describing how individual values will be transformed and validated.
     */
    open var field:Field<T>
    
    public init(_ field:Field<T>, value:U?=nil, name:String?=nil, priority:Int?=nil, key:String?=nil) {
        self.field = field
        super.init(value: value, name: name ?? field.name, priority: priority ?? field.priority, key:key ?? field.key)
    }
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
open class ArrayField<T:Equatable>: WrapperField<T, [T]> {
    open var allowsDuplicates: Bool = true
    
    public convenience init(_ field:Field<T>, value:[T]?=[], name:String?=nil, priority:Int?=nil, key:String?=nil, allowsDuplicates: Bool) {
        self.init(field, value: value, name: name, priority: priority, key: key)
        self.allowsDuplicates = allowsDuplicates
    }
    
    public override init(_ field:Field<T>, value:[T]?=[], name:String?=nil, priority:Int?=nil, key:String?=nil) {
        super.init(field, value: value, name: name, priority: priority, key: key)
    }
    
    open override func constrain(_ value: Array<T>?) -> Array<T>? {
        if let value = value {
            var constrainedValue = value.flatMap { self.field.constrain($0) }
            if !self.allowsDuplicates {
               constrainedValue = constrainedValue.uniqueElements
            }
            return constrainedValue
        } else {
            return value
        }
    }
    
    open override func isChange(oldValue: [T]?, newValue: [T]?) -> Bool {
        // Consider any update a change
        return true
    }

    @discardableResult open func append(_ value:T) -> Bool {
        if let value = self.field.constrain(value) {
            if !self.allowsDuplicates && self.contains(value) {
                return false
            } else {
                self.value?.append(value)
                self.valueAdded(value)
                return true
            }
        }
        
        return false
    }
    
    @discardableResult open func removeFirst(_ value:T) -> Bool {
        if let index = self.value?.index(of: value) {
            self.removeAtIndex(index)
            return true
        }
        return false
    }
    
    open func contains(_ value: T) -> Bool {
        return self.value?.index(of: value) != nil
    }

    open func removeAtIndex(_ index:Int) {
        let value = self.value?[index]
        self.value?.remove(at: index)
        if let value = value {
            self.valueRemoved(value)
        }
    }
    
    // MARK: - Dictionary values
    
    open func buildValueTransformer() -> ArrayValueTransformer<T> {
        return ArrayValueTransformer<T>()
    }
    
    open override func defaultValueTransformer(in context: ValueTransformerContext = .defaultContext) -> ValueTransformer<[T]> {
        let transformer = self.buildValueTransformer()
        if let innerTransformer = self.field.valueTransformer(in: context) {
            transformer.innerTransformer = innerTransformer
        }
        return transformer
    }
    
    open func valueRemoved(_ value: T) {
    }
    
    open func valueAdded(_ value: T) {
    }
    
    open override func processNewValue(_ value: [T]?) {
        super.processNewValue(value)
        if let value = value {
            for item in value {
                self.processNewValue(item)
            }
        }
    }

    open func processNewValue(_ value: T?) {
    }
    
    
}
