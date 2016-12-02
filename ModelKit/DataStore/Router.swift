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
    /**
     Generates the path to a model.
     */
    func path(for model: Model) -> String?
    
    /**
     Generates the path to a collection.
     */
    func path(for modelClass: Model.Type) -> String?
    
    /**
     Generates the path to a collection owned by another model through a field.
     */
    func path<T: Model, U: Model>(for model: T, field: ModelArrayField<U>) -> String?

    /**
     Generates the path to a member of a collection owned by another model through a field.
     */
    func path<T: Model, U: Model>(for model: T, field: ModelArrayField<U>, child: U) -> String?
}

enum CaseConvention {
    case upperCamel
    case lowerCamel
    case snake
}

open class RESTRouter: ModelRouter {
    var collectionNames = TypeDictionary<String>()
    var pluralizesCollections = true
    
    let pathSeparator = "/"
    
    public func route(_ modelClass: Model.Type, to path: String) {
        self.collectionNames[modelClass] = path
    }

    public func unroute(_ modelClass: Model.Type) {
        self.collectionNames.remove(modelClass)
    }
    
    open func path(for model: Model) -> String? {
        if let id = model.identifier, let collectionPath = self.path(for: type(of: model)) {
            return "\(collectionPath)/\(id)"
        } else {
            return nil
        }
    }

    open func path<T: Model, U: Model>(for model: T, field: ModelArrayField<U>) -> String? {
        guard let path      = self.path(for: model) else { return nil }
        guard let fieldKey  = field.key else { return nil }
        return [path, fieldKey].joined(separator: pathSeparator)
    }

    public func path<T: Model, U: Model>(for model: T, field: ModelArrayField<U>, child: U) -> String? {
        guard let prefix = self.path(for: model, field: field) else { return nil }
        guard let id = child.identifier else { return nil }
        
        return [prefix, id].joined(separator: pathSeparator)
    }
    
    open func path(for modelClass: Model.Type) -> String? {
        if let mapped = self.collectionNames[modelClass] {
            return mapped
        } else {
            return self.stringify(modelClass)
        }
    }
    
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
