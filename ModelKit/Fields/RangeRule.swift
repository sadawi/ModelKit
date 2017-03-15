//
//  RangeRule.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

open class RangeRule<T:Comparable>: ValidationRule<T> {
    var minimum:T?
    var maximum:T?
    
    public init(minimum:T?=nil, maximum:T?=nil) {
        super.init()
        self.minimum = minimum
        self.maximum = maximum
    }
    
    override func validate(_ value: T) -> Bool {
        if let minimum = self.minimum {
            if value < minimum {
                self.message = "must be greater than \(minimum)"
                return false
            }
        }
        if let maximum = self.maximum {
            if value > maximum {
                self.message = "must be less than \(maximum)"
                return false
            }
        }
        return true
    }
}

