//
//  SimpleValueTransformer.swift
//  ModelKit
//
//  Created by Sam Williams on 12/7/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

/**
 The simplest working implementation of a transformer: just attempts to cast between T and Any
 */
open class SimpleValueTransformer<T>: ValueTransformer<T> {
    open override func importValue(_ value: Any?, in context: ValueTransformerContext = .defaultContext) -> T? {
        if let castValue = value as? T {
            return castValue
        } else {
            return nil
        }
    }
    
    open override func exportValue(_ value: T?, in context: ValueTransformerContext = .defaultContext) -> Any? {
        if let value = value {
            return value as Any?
        } else {
            return type(of: self).nullValue(explicit: context.explicitNull)
        }
    }
}
