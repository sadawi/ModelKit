//
//  TransformerRule.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

open class TransformerRule<FromType, ToType>: ValidationRule<FromType> {
    var rule:ValidationRule<ToType>?
    var transform:((FromType) -> ToType?)?
    
    var transformationDescription: String?
    
    override init() {
        super.init()
    }
    
    override func validate(_ value: FromType) -> Bool {
        let transformed = self.transform?(value)
        if let rule = self.rule {
            return rule.validate(transformed)
        } else {
            // Is this the right default?
            return false
        }
    }
    
    override var message: String? {
        get {
            if let transformationDescription = self.transformationDescription, let message = self.rule?.message {
                return "\(transformationDescription) \(message)"
            } else {
                return self.rule?.message
            }
        }
        set {
            // Nothing
        }
    }
}

