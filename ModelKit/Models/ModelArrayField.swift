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
    open weak var model: Model?
    open var findInverse: ((T)->ModelFieldType)?
    open var foreignKey: Bool = false
    open var cascadeDelete: Bool = true
    
    private var modelLookup: [Identifier: T] = [:]
    
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
    
    public init(_ field:ModelField<T>, value:[T]?=[], name:String?=nil, priority:Int=0, key:String?=nil, inverse: ((T)->ModelFieldType)?=nil) {
        super.init(field, value: value, name: name, priority: priority, key: key)
        self.foreignKey = field.foreignKey
        self.findInverse = inverse ?? field.findInverse
    }
    
    public func contains(_ value: T) -> Bool {
        if let identifier = value.identifier {
            return self.modelLookup[identifier] != nil
        } else {
            return false
        }
    }
    
    open override func valueRemoved(_ value: T) {
        if let identifier = value.identifier {
            self.modelLookup.removeValue(forKey: identifier)
        }
        
        self.inverse(on: value)?.inverseValueRemoved(self.model)
    }
    
    open override func valueAdded(_ value: T) {
        if let identifier = value.identifier {
            self.modelLookup[identifier] = value
        }
        
        self.inverse(on: value)?.inverseValueAdded(self.model)
    }
    
    open func inverse(on model:T) -> ModelFieldType? {
        return self.findInverse?(model)
    }
    
    // MARK: - ModelFieldType
    
    open func inverseValueAdded(_ value: Model?) {
        if let value = value as? T, !self.contains(value){
            self.append(value)
        }
    }
    
    open func inverseValueRemoved(_ value: Model?) {
        if let value = value as? T, self.contains(value) {
            self.removeFirst(value)
        }
    }
    
    var modelValue: [Model]? {
        return self.value
    }
    
}

public postfix func *<T:Model>(right:ModelField<T>) -> ModelArrayField<T> {
    return ModelArrayField<T>(right)
}
