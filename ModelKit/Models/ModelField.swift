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
    var ownerModel: Model? { get set }
    var foreignKey:Bool { get set }
    var cascadeDelete: Bool { get }
    
    func addObserver(updateImmediately: Bool, action: @escaping ((FieldPath) -> Void))

    func inverseValueRemoved(_ value: Model?)
    func inverseValueAdded(_ value: Model?)
}

public extension ModelFieldType {
    public var ownerModel: Model? {
        get {
            return self.owner as? Model
        }
        set {
            self.owner = newValue
        }
    }
    
    public func addObserver(action: @escaping ((FieldPath) -> Void)) {
        self.addObserver(updateImmediately: false, action: action)
    }
}

public protocol InvertibleModelFieldType: ModelFieldType {
    func inverse() -> ModelFieldType?
}

open class ModelField<T: Model>: Field<T>, InvertibleModelFieldType {
    open var foreignKey:Bool = false
    open var cascadeDelete: Bool = true
    
    public var findInverse: ((T)->ModelFieldType)?
    
    public init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil, foreignKey:Bool=false, inverse: ((T)->ModelFieldType)?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
        self.foreignKey = foreignKey
        self.findInverse = inverse
    }
    
    public required init(value: T?, name: String?, priority: Int, key: String?) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    open override func defaultValueTransformer(in context: ValueTransformerContext) -> ValueTransformer<T> {
        return self.foreignKey ? ModelForeignKeyValueTransformer<T>.sharedInstance : ModelValueTransformer<T>.sharedInstance
    }
    
    /**
     Attempts to find the inverse field on a model value, as defined by the `inverse` closure parameter specified in `init`.
     For example, when looking at a `employee.company`, this might point to a company's `employees` field.
     */
    open func inverse(on model:T) -> ModelFieldType? {
        return self.findInverse?(model)
    }
    
    open func inverse() -> ModelFieldType? {
        if let value = self.value {
            return self.inverse(on: value)
        } else {
            return nil
        }
    }
    
    open override func valueUpdated(oldValue:T?, newValue: T?) {
        super.valueUpdated(oldValue: oldValue, newValue: newValue)
        
        if oldValue != newValue {
            if let value = oldValue {
                let inverseField = self.inverse(on: value)
                inverseField?.inverseValueRemoved(self.ownerModel)
            }
            if let value = newValue {
                let inverseField = self.inverse(on: value)
                inverseField?.inverseValueAdded(self.ownerModel)
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
    
    open override func writeUnseenValue(to dictionary: inout AttributeDictionary, seenFields: inout [FieldType], key: String, in context: ValueTransformerContext) {
        if let modelValueTransformer = self.valueTransformer() as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, seenFields: &seenFields, in: context)
        } else { 
            super.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key, in: context)
        }
    }
    
    open override func writeSeenValue(to dictionary: inout AttributeDictionary, seenFields: inout [FieldType], key: String, in context: ValueTransformerContext) {
        // Only writes the identifier field, if it exists
        if let identifierField = self.value?.identifierField, let modelValueTransformer = self.valueTransformer(in: context) as? ModelValueTransformer<T> {
            dictionary[key] = modelValueTransformer.exportValue(self.value, fields: [identifierField], seenFields: &seenFields, in: context)
        }
    }
    
    open override func processNewValue(_ value: T?) {
        super.processNewValue(value)
    }
    
    open func addObserver(updateImmediately: Bool, action: @escaping ((FieldPath) -> Void)) {
        // TODO
    }

}
