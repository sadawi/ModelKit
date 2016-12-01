//
//  File.swift
//  Pods
//
//  Created by Sam Williams on 11/25/15.
//
//

import Foundation

open class Field<T:Equatable>: BaseField<T>, Equatable {
    open var valueTransformers:[String:ValueTransformer<T>] = [:]
    
    public override init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    /**
     Sets a ValueTransformer for this field.
     
     - parameter transformer: The ValueTransformer to set
     - parameter in: A ValueTransformerContext used to identify this transformer. If omitted, will be the default context.
     */
    @discardableResult open func transform(_ transformer:ValueTransformer<T>,
                                           in context:ValueTransformerContext=ValueTransformerContext.defaultContext) -> Self {
        self.valueTransformers[context.name] = transformer
        return self
    }
    
    /**
     Adds a value transformer (with optional context) for this field.
     
     - parameter importValue: A closure mapping an external value (e.g., a string) to a value for this field.
     - parameter exportValue: A closure mapping a field value to an external value
     - parameter in: A ValueTransformerContext used to identify this transformer. If omitted, will be the default context.
     */
    @discardableResult open func transform(importValue:@escaping ((AnyObject?) -> T?), exportValue:@escaping ((T?) -> AnyObject?), in context: ValueTransformerContext = ValueTransformerContext.defaultContext) -> Self {
        
        self.valueTransformers[context.name] = ValueTransformer(importAction: importValue, exportAction: exportValue)
        return self
    }
    
    open func defaultValueTransformer() -> ValueTransformer<T> {
        return SimpleValueTransformer<T>()
    }
    
    open override func valueUpdated(oldValue:T?, newValue: T?) {
        super.valueUpdated(oldValue: oldValue, newValue: newValue)
        if oldValue != self.value {
            self.valueChanged()
        }
    }
    
    // MARK: Value transformers
    
    /**
     Finds a value transformer (either in the default transformer context or a specified one) for this field.
     
     Priority:
     - A transformer manually specified on this field (for the specified context)
     - This field's default transformer
     */
    open func valueTransformer(in context: ValueTransformerContext = ValueTransformerContext.defaultContext) -> ValueTransformer<T>? {
        if let transformer = self.valueTransformers[context.name] {
            return transformer
        } else {
            return self.defaultValueTransformer()
        }
    }
    
    // MARK: - Dictionary values
    
    open override func read(from dictionary:[String:AnyObject]) {
        if let key = self.key, let dictionaryValue = dictionary[key], let transformer = self.valueTransformer() {
            self.value = transformer.importValue(dictionaryValue)
        }
    }

    open override func writeUnseenValue(to dictionary: inout [String : AnyObject], seenFields: inout [FieldType], key: String, explicitNull: Bool = false) {
        if let transformer = self.valueTransformer() {
            dictionary[key] = transformer.exportValue(self.value, explicitNull: explicitNull)
        }
    }

    open override func writeSeenValue(to dictionary: inout [String : AnyObject], seenFields: inout [FieldType], key: String) {
        self.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key)
    }

}

public func ==<T:Equatable>(left: Field<T>, right: Field<T>) -> Bool {
    return left.value == right.value
}

