//
//  ModelField.swift
//  APIKit
//
//  Created by Sam Williams on 12/8/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public enum DeleteBehavior {
    case nullify
    case delete
}

public protocol ModelFieldType: FieldType {
    var model: Model? { get set }
    var foreignKey:Bool { get set }
    var cascadeDelete: Bool { get }

    func inverseValueRemoved(_ value: Model?)
    func inverseValueAdded(_ value: Model?)
}

open class ModelField<T: Model>: Field<T>, ModelFieldType {
    open var foreignKey:Bool = false
    open weak var model: Model?
    
    open var cascadeDelete: Bool = true
    
    open var inverse: ((T)->ModelFieldType)?
    
    public init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil, foreignKey:Bool=false, inverse: ((T)->ModelFieldType)?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
        self.foreignKey = foreignKey
        self.inverse = inverse
    }
    
    open override func defaultValueTransformer() -> ValueTransformer<T> {
        return self.foreignKey ? ModelForeignKeyValueTransformer<T>.sharedInstance : ModelValueTransformer<T>.sharedInstance
    }
    
    open func inverse(of model:T) -> ModelFieldType? {
        return self.inverse?(model)
    }
    
    open override func valueUpdated(oldValue:T?, newValue: T?) {
        super.valueUpdated(oldValue: oldValue, newValue: newValue)
        
        if oldValue != newValue {
            if let value = oldValue {
                let inverseField = self.inverse(of: value)
                inverseField?.inverseValueRemoved(self.model)
            }
            if let value = newValue {
                let inverseField = self.inverse(of: value)
                inverseField?.inverseValueAdded(self.model)
            }
        }
    }
    
    open func requireValid() -> Self {
        return self.require(message: "Value is invalid", allowNil:true) { value in
            return value.validate().isValid
        }
    }
    
    // MARK: - ModelFieldType
    
    open func inverseValueAdded(_ value: Model?) {
        if let value = value as? T {
            self.value = value
        }
    }
    
    open func inverseValueRemoved(_ value: Model?) {
        self.value = nil
    }
    
    var modelValue: Model? {
        return self.value
    }
    
    
    open override func writeUnseenValue(to dictionary: inout [String : AnyObject], seenFields: inout [FieldType], key: String, explicitNull: Bool = false, in context: ValueTransformerContext) {
        if let modelValueTransformer = self.valueTransformer() as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, seenFields: &seenFields, explicitNull: explicitNull)
        } else { 
            super.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key, explicitNull: explicitNull, in: context)
        }
    }
    
    open override func writeSeenValue(to dictionary: inout [String : AnyObject], seenFields: inout [FieldType], key: String, in context: ValueTransformerContext) {
        // Only writes the identifier field, if it exists
        if let identifierField = self.value?.identifierField, let modelValueTransformer = self.valueTransformer(in: context) as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, fields: [identifierField], seenFields: &seenFields)
        }
    }
}
