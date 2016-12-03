//
//  MemoryRegistry.swift
//  ModelKit
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

/**
 A very simple ModelRegistry adapter for a MemoryModelStore
 */
public struct MemoryRegistry: ModelRegistry {
    var memory: MemoryModelStore
    
    public init() {
        self.memory = MemoryModelStore.sharedInstance
    }
    
    public init(modelStore: MemoryModelStore) {
        self.memory = modelStore
    }
    
    public func didInstantiate<T:Model>(_ model: T) {
        if model.identifier != nil {
            self.memory.updateImmediately(model)
        }
    }
    
    public func canonicalModel<T:Model>(for model: T) -> T? {
        if let identifier = model.identifier {
            return self.memory.lookupImmediately(T.self, identifier: identifier)
        } else {
            return nil
        }
    }
}

