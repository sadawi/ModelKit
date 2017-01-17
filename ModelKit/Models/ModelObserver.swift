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
    public typealias Action = ((Model, FieldPath) -> ())
    public var uuid = UUID()
    public var fieldPath: FieldPath?
    public var action:Action?
    
    public init(fieldPath: FieldPath?=nil, action: @escaping Action) {
        self.action = action
        self.fieldPath = fieldPath
    }
    
    public func perform(model: Model, fieldPath: FieldPath) {
        if let selfFieldPath = self.fieldPath {
            if selfFieldPath.matches(fieldPath) {
                self.action?(model, fieldPath)
            }
        } else {
            self.action?(model, fieldPath)
        }
    }
}
