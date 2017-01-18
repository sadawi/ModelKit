//
//  ModelObserver.swift
//  ModelKit
//
//  Created by Sam Williams on 12/11/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol ModelObserver: class {
    func modelChanged(_ model: Model, at: FieldPath)
}

open class ModelObservation: Observation {
    public typealias Action = ((Model, FieldPath) -> Void)
    public var uuid = UUID()
    public var fieldPath: FieldPath?
    public var action:Action?
    
    public init(fieldPath: FieldPath?=nil, action: @escaping Action) {
        self.action = action
        self.fieldPath = fieldPath
    }
    
    open func matches(fieldPath: FieldPath) -> Bool {
        if let selfFieldPath = self.fieldPath {
            return selfFieldPath.matches(fieldPath)
        } else {
            return true
        }
    }
    
    public func perform(model: Model, fieldPath: FieldPath) {
        if self.matches(fieldPath: fieldPath) {
            self.action?(model, fieldPath)
        }
    }
}
