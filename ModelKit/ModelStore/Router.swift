//
//  Router.swift
//  ModelKit
//
//  Created by Sam Williams on 12/2/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation
import StringInflections

open class RESTRouter {
    var collectionNames = TypeDictionary<String>()
    var pluralizesCollections = true
    
    let pathSeparator = "/"
    
    public init() {
        
    }
    
    public func route(_ modelClass: Model.Type, to path: String) {
        self.collectionNames[modelClass] = path
    }

    public func unroute(_ modelClass: Model.Type) {
        self.collectionNames.remove(modelClass)
    }
    
    public func path(to model: Model) -> String? {
        if let collectionPath = self.path(to: type(of: model)) {
            return self.path(to: model, in: collectionPath)
        } else {
            return nil
        }
    }
    
    public func path(to model: Model, in collectionPath: String) -> String? {
        if let id = model.identifier {
            return "\(collectionPath)/\(id)"
        } else {
            return nil
        }
    }

    public func path<T: Model>(to field: ModelArrayField<T>) -> String? {
        guard let owner     = field.model else { return nil }
        guard let path      = self.path(to: owner) else { return nil }
        guard let fieldKey  = field.key else { return nil }
        return [path, fieldKey].joined(separator: pathSeparator)
    }

    public func path<T: Model>(to child: T, in field: ModelArrayField<T>) -> String? {
        guard let prefix = self.path(to: field) else { return nil }
        guard let id = child.identifier else { return nil }
        
        return [prefix, id].joined(separator: pathSeparator)
    }
    
    open func path(to modelClass: Model.Type) -> String? {
        if let mapped = self.collectionNames[modelClass] {
            return mapped
        } else {
            return self.stringify(modelClass)
        }
    }
    
    /**
     Generates the path to the collection containing a model. If the model conforms to `HasOwnerField` and has a non-nil owner field,
     that field will be used to generate the path (e.g., "companies/4/employees/1")
     */
    public func collectionPath<T: Model>(for model: T) -> String? {
        if let ownedModel = model as? HasOwnerField,
            let ownerField = ownedModel.ownerField as? InvertibleModelFieldType,
            let inverseField = ownerField.inverse() as? ModelArrayField<T>
        {
            return self.path(to: inverseField)
        } else {
            return self.path(to: T.self)
        }
    }
    
    public func instancePath<T: Model>(for model: T) -> String? {
        if let collectionPath = self.collectionPath(for: model) {
            return self.path(to: model, in: collectionPath)
        } else {
            return nil
        }
    }
    
    // MARK: - Utilities
    
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
