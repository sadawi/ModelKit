//
//  LengthRule.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

open class LengthRule: TransformerRule<String, Int> {
    public convenience init(length: Int?) {
        self.init(minimum: length, maximum: length)
    }
    
    public init(minimum:Int?=nil, maximum:Int?=nil) {
        super.init()
        self.transform = { $0.characters.count }
        self.rule = RangeRule(minimum: minimum, maximum: maximum)
        self.transformationDescription = "length"
    }
}

