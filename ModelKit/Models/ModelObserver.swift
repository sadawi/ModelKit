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
    public typealias Action = ((Model, FieldPath, inout Set<Model>) -> Void)
    public var uuid = UUID()
    public var fieldPath: FieldPath?
    public var action:Action?
    
    public init(fieldPath: FieldPath?=nil, action: @escaping Action) {
        self.action = action
        self.fieldPath = fieldPath
    }
    
    open func matches(fieldPath changedFieldPath: FieldPath) -> Bool {
        if let observedFieldPath = self.fieldPath {
            // Either or both may be a prefix path, which must be the receiver of a .matches() call
            return changedFieldPath.matches(observedFieldPath) || observedFieldPath.matches(changedFieldPath)
        } else {
            return true
        }
    }
    
    public func perform(model: Model, fieldPath: FieldPath, seen: inout Set<Model>) {
        if self.matches(fieldPath: fieldPath) {
            self.action?(model, fieldPath, &seen)
        }
    }
}
