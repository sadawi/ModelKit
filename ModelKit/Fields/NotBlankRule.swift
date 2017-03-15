//
//  NotBlankRule.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

public protocol Blankable {
    var isBlank: Bool { get }
}

extension String: Blankable {
    public var isBlank: Bool {
        return self.isEmpty
    }
}

extension Array: Blankable {
    public var isBlank: Bool {
        return self.isEmpty
    }
}

open class NotBlankRule<T: Blankable>: ValidationRule<T> {
    override public init() {
        super.init()
        self.message = "cannot be blank"
    }
    
    override open func validate(_ value: T?) -> Bool {
        if let v = value {
            return !v.isBlank
        } else {
            return false
        }
    }
}

