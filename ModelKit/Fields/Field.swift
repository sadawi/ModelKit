//
//  File.swift
//  Pods
//
//  Created by Sam Williams on 11/25/15.
//
//

import Foundation

open class Field<T:Equatable>: BaseField<T> {
    public override init(value:T?=nil, name:String?=nil, priority:Int=0, key:String?=nil) {
        super.init(value: value, name: name, priority: priority, key: key)
    }
    
    open override func valueUpdated(oldValue:T?, newValue: T?) {
        super.valueUpdated(oldValue: oldValue, newValue: newValue)
        if oldValue != self.value {
            self.valueChanged()
        }
    }
    
    // MARK: - Dictionary values
    
    open override func read(from dictionary:[String:AnyObject], in context: ValueTransformerContext) {
        if let key = self.key, let dictionaryValue = dictionary[key], let transformer = self.valueTransformer(in: context) {
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
