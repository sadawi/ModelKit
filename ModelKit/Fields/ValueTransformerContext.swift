//
//  ValueTransformerContext.swift
//  ModelKit
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation
import StringInflections

/**
 An object that identifies a particular system of transformations. For example, there might be one context for writing to a JSON API,
 and another for writing user-readable strings.
 */
open class ValueTransformerContext {
    public var name: String
    
    // TODO: remove explicit key from fields entirely, configure entirely in context.
    public var keyCase: StringCase? = nil
    
    public init(name: String) {
        self.name = name
    }
}

public extension ValueTransformerContext {
    static let defaultContext = ValueTransformerContext(name: "default")
}
