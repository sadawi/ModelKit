//
//  Observation.swift
//  Pods
//
//  Created by Sam Williams on 11/28/15.
//
//

import Foundation

public protocol Observation: AnyObject {
    associatedtype Action
    
    var action:Action? { get set }
    var uuid: UUID { get }
}
