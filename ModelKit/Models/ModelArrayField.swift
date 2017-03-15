//
//  ModelArrayField.swift
//  ModelKit
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol ModelArrayFieldType: ModelFieldType {
}

open class ModelArrayField<T: Model>: ArrayField<T>, ModelArrayFieldType {
    open var findInverse: ((T)->ModelFieldType)?
    open var foreignKey: Bool = false
    open var cascadeDelete: Bool = true
    
    private var modelLookup: [Identifier: T] = [:]

    public var modelObservations = ObservationRegistry<ModelObservation>()
    
    open override var value:[T]? {
        didSet {
            let oldValues = oldValue ?? []
            let newValues = self.value ?? []
            
            let (removed, added) = oldValues.symmetricDifference(newValues)
            
            for value in removed {
                self.valueRemoved(value)
            }
            for value in added {
                self.valueAdded(value)
            }
            self.valueUpdated(oldValue: oldValue, newValue: self.value)
        }
    }
    
    public init(_ field:ModelField<T>, value:[T]?=[], name:String?=nil, priority:Int?=nil, key:String?=nil, inverse: ((T)->ModelFieldType)?=nil) {
        super.init(field, value: value, name: name, priority: priority, key: key)
        self.foreignKey = field.foreignKey
        self.findInverse = inverse ?? field.findInverse
    }
    
    public func hasMemberWithIdentifier(of value: T) -> Bool? {
        if let identifier = value.identifier {
            return self.modelLookup[identifier] != nil
        } else {
            return nil
        }
    }
    
    open override func valueRemoved(_ value: T) {
        if let identifier = value.identifier {
            self.modelLookup.removeValue(forKey: identifier)
        }
        
        self.inverse(on: value)?.inverseValueRemoved(self.ownerModel)
    }
    
    open override func valueAdded(_ value: T) {
        if let identifier = value.identifier {
            self.modelLookup[identifier] = value
        }
        
        self.inverse(on: value)?.inverseValueAdded(self.ownerModel)
    }
    
    open func inverse(on model:T) -> ModelFieldType? {
        return self.findInverse?(model)
    }
    
    // MARK: - ModelFieldType
    
    /**
     Handle the event where this field's inverse field had a new value added.
     */
    open func inverseValueAdded(_ value: Model?) {
        // We're checking containment by id. If we can't do that, don't do anything.
        guard value?.identifier != nil else { return }
        
        if let value = value as? T, self.hasMemberWithIdentifier(of: value) == false {
            self.append(value)
        }
    }
    
    open func inverseValueRemoved(_ value: Model?) {
        if let value = value as? T, self.hasMemberWithIdentifier(of: value) == true {
            self.removeFirst(value)
        }
    }
    
    open override func processNewValue(_ value: T?) {
        super.processNewValue(value)
    }
    
    open func addObserver(updateImmediately: Bool, action: @escaping ((FieldPath) -> Void)) {
        // TODO
    }
    
    // MARK: - 
    
    open override func buildValueTransformer() -> ArrayValueTransformer<T> {
        return ModelArrayValueTransformer<T>()
    }
    
    open override func writeUnseenValue(to dictionary: inout AttributeDictionary, seenFields: inout [FieldType], key: String, in context: ValueTransformerContext) {
        if let transformer = self.valueTransformer() as? ModelArrayValueTransformer<T> {
            dictionary[key] = transformer.exportValue(self.value, seenFields: &seenFields, in: context)
        } else {
            super.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key, in: context)
        }
    }

}

public postfix func *<T:Model>(right:ModelField<T>) -> ModelArrayField<T> {
    return ModelArrayField<T>(right)
}
