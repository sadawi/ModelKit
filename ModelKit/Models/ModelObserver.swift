//
//  ModelObserver.swift
//  ModelKit
//
//  Created by Sam Williams on 12/11/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol ModelObserver {
    func modelChanged(_ model: Model, at: FieldPath)
}

open class ModelObservation: Observation {
    public typealias Action = ((Model) -> Void)
    public var uuid = UUID()
}
