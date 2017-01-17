//
//  ValueObservation.swift
//  ModelKit
//
//  Created by Sam Williams on 1/9/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation


/**
 An object that holds a closure that is to be run when a value changes.
 
 `Observation` instances are themselves `Observable`, which means they can be chained:
 ```
 let a = Field<String>()
 let b = Field<String>()
 let c = Field<String>()
 a --> b --> c
 ```
 */
open class ValueObservation<T>: Observation {
    public typealias Action = ((T?) -> Void)
    public var uuid = UUID()
    
    public typealias ObservedValueType = T
    
    public var action:Action?
    
    open func valueChanged(_ newValue:T?) {
        self.action?(newValue)
    }
}
