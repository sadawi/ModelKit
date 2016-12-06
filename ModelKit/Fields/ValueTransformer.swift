//
//  FieldSerializer.swift
//  Pods
//
//  Created by Sam Williams on 12/7/15.
//
//

import Foundation

public protocol ValueTransformerType {
}

/**
 A strongly typed transformer between Any and a particular type.
 The default implementation does nothing (i.e., everything is mapped to nil).
 */
open class ValueTransformer<T>: ValueTransformerType {
    public typealias ImportActionType = ((Any?, ValueTransformerContext) -> T?)
    public typealias ExportActionType = ((T?, ValueTransformerContext) -> Any?)
    
    var importAction: ImportActionType?
    var exportAction: ExportActionType?
    
    public required init() {
        
    }
    
    public init(importAction:@escaping ImportActionType, exportAction:@escaping ExportActionType) {
        self.importAction = importAction
        self.exportAction = exportAction
    }
    
    /**
     Attempts to convert an external value to an internal form.  If that's not possible, or if the external value is nil, returns nil.
     */
    open func importValue(_ value:Any?, in context: ValueTransformerContext = .defaultContext) -> T? {
        return self.importAction?(value, context)
    }

    /**
     Transforms a value into an external form suitable for serialization.
     - parameter explicitNull: If false, export nil values as nil. If true, export nil values as a special null value (defaulting to NSNull)
     */
    open func exportValue(_ value:T?, explicitNull: Bool = false, in context: ValueTransformerContext = .defaultContext) -> Any? {
        if let exportAction = self.exportAction, let exportedValue = exportAction(value, context) {
            return exportedValue
        } else {
            return type(of: self).nullValue(explicit: explicitNull)
        }
    }
    
    /**
     Generates an external value representing nil.
     - parameter explicit: Whether the value should be a special (non-nil) value.
     */
    open class func nullValue(explicit: Bool = false) -> Any? {
        return explicit ? NSNull() : nil
    }
    
    /**
     Determine whether an external value represents nil.  By default, this will be true for `nil` and `NSNull` instances.
     */
    open class func valueIsNull(_ value: Any?) -> Bool {
        return value == nil || value is NSNull
    }
}

/**
 The simplest working implementation of a transformer: just attempts to cast between T and Any
 */
open class SimpleValueTransformer<T>: ValueTransformer<T> {
    open override func importValue(_ value: Any?, in context: ValueTransformerContext = .defaultContext) -> T? {
        if let castValue = value as? T {
            return castValue
        } else if let objectCastValue = (value as AnyObject?) as? T {
            // We might get better results by casting to an object first.
            // For example, if value is a Double, `value as? Float` will be nil (probably wrong), but `(value as AnyObject?) as? Float` will not.
            return objectCastValue
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value: T?, explicitNull: Bool, in context: ValueTransformerContext = .defaultContext) -> Any? {
        if let value = value {
            return value as Any?
        } else {
            return type(of: self).nullValue(explicit: explicitNull)
        }
    }
}
