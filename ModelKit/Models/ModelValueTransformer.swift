//
//  ModelValueTransformer.swift
//  Pods
//
//  Created by Sam Williams on 12/8/15.
//
//

import Foundation

open class ModelValueTransformer<T: Model>: ValueTransformer<T> {
    
    public required init() {
        super.init()
    }

    open override func importValue(_ value: Any?) -> T? {
        // TODO: conditionally casting to AttributeDictionary might be slowish
        if let value = value as? AttributeDictionary {
            return T.from(dictionaryValue: value)
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value: T?, explicitNull: Bool = false) -> Any? {
        var seenFields: [FieldType] = []
        return self.exportValue(value, seenFields: &seenFields, explicitNull: explicitNull)
    }

    open func exportValue(_ value: T?, fields: [FieldType]?=nil, seenFields: inout [FieldType], explicitNull: Bool = false) -> Any? {
        // Why do I have to cast it to Model?  T is already a Model.
        if let value = value as? Model {
            return value.dictionaryValue(fields: fields, seenFields: &seenFields, explicitNull: explicitNull) as Any
        } else {
            return type(of: self).nullValue(explicit: explicitNull)
        }
    }
}

open class ModelForeignKeyValueTransformer<T: Model>: ValueTransformer<T> {
    public required init() {
        super.init(importAction: { value in
            
            // Normally we'd check for null by simply trying to cast to the correct type, but only a model instance knows the type of its identifier field.
            if let value = value , !ModelForeignKeyValueTransformer<T>.valueIsNull(value) {
                
                // Attempt to initialize an object with just an id value
                let dummy = Model.prototype(for: T.self)
                if let idField = dummy.identifierField, let idKey = idField.key {
                    let attributes = [idKey: value]
                    let model = T.from(dictionaryValue: attributes) { model, isNew in
                        // We only know it's definitely a shell if it wasn't reused from an existing model
                        if isNew {
                            model.loadState = .incomplete
                        }
                    }
                    return model
                }
            }
            return nil
            },
            exportAction: { value in
                if let value = value as? Model {
                    return value.identifierField?.anyObjectValue
                } else {
                    return nil
                }
            }
        )
    }
    
}
