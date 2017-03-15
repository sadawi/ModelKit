//
//  CharacterSetRule.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

open class CharacterSetRule: ValidationRule<String> {
    open var characterSet: CharacterSet
    
    public init(characterSet: CharacterSet) {
        self.characterSet = characterSet
        super.init()
        self.message = "contains invalid characters"
    }
    
    override open func validate(_ value: String?) -> Bool {
        if let v = value {
            // Crash in .isSuperSet(of:)
            // see https://forums.developer.apple.com/thread/63262
            
            return v.rangeOfCharacter(from: self.characterSet.inverted) == nil
        } else {
            return true
        }
    }
    
}
