//
//  Router.swift
//  ModelKit
//
//  Created by Sam Williams on 12/2/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation
import StringInflections

public protocol ModelRouter {
    func path(for model: Model) -> String?
    func path(for modelClass: Model.Type) -> String?
}

enum CaseConvention {
    case upperCamel
    case lowerCamel
    case snake
}

open class RESTRouter: ModelRouter {
    var collectionNames = TypeDictionary<String>()
    var pluralizesCollections = true
    
    public func route(_ modelClass: Model.Type, to path: String) {
        self.collectionNames[modelClass] = path
    }
    
    open func path(for model: Model) -> String? {
        if let id = model.identifier, let collectionPath = self.path(for: type(of: model)) {
            return "\(collectionPath)/\(id)"
        } else {
            return nil
        }
    }
    
    open func path(for modelClass: Model.Type) -> String? {
        if let mapped = self.collectionNames[modelClass] {
            return mapped
        } else {
            return self.stringify(modelClass)
        }
    }
    
    // TODO: should cache results
    open func stringify(_ modelClass: Model.Type) -> String? {
        var string = String(describing: modelClass)
        string = string.replacingOccurrences(of: "(", with: "")
        let parts = string.components(separatedBy: " in ")
        if let cleanName = parts.first {
            return cleanName.pluralized().underscored()
        }
        return nil
    }
}
