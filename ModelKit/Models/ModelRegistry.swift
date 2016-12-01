//
//  ModelRegistry.swift
//  ModelKit
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

/**
 An object that keeps track of canonical model instances, presumably indexed by identifier.
 */
public protocol ModelRegistry {
    /// Registers a new model in the registry.
    func didInstantiate<T:Model>(_ model:T)
    
    /// Tries to find a registered canonical instance matching the provided model.  Should return nil if no such object has been registered.
    func canonicalModel<T:Model>(for model:T) -> T?
}
