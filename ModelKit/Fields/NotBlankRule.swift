//
//  NotBlankRule.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

open class NotBlankRule: ValidationRule<String> {
    override public init() {
        super.init()
        self.message = "cannot be blank"
    }
    
    override open func validate(_ value: String?) -> Bool {
        if let v = value {
            return v.characters.count > 0
        } else {
            return false
        }
    }
}

