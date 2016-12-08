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
    var maxPathDepth: Int
    
    let pathSeparator = "/"
    
    public init(maxPathDepth: Int=1) {
        self.maxPathDepth = maxPathDepth
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

    public func path(to field: ModelFieldType, maxDepth: Int=0) -> String? {
        guard let owner     = field.model else { return nil }
        guard let path      = self.instancePath(for: owner, maxDepth: maxDepth) else { return nil }
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
     Generates the path to the collection containing a model. 
     
     If the model conforms to `HasOwnerField` and has a non-nil owner field, that field will be used to generate the path (e.g., "companies/4/employees/1").
     
     - parameter maxDepth: The number of owner objects to include in the path. 0 => "employees", 1 => "companies/4/employees", 2 => "regions/9/companies/4/employees", etc.
     */
    public func collectionPath<T: Model>(for model: T, maxDepth: Int? = nil) -> String? {
        let maxDepth = maxDepth ?? self.maxPathDepth
        
        if maxDepth > 0,
            let ownedModel = model as? HasOwnerField,
            let ownerField = ownedModel.ownerField as? InvertibleModelFieldType,
            let inverseField = ownerField.inverse()
        {
            return self.path(to: inverseField, maxDepth: maxDepth-1)
        } else {
            return self.path(to: type(of: model))
        }
    }
    
    
    /**
     Generates the path to a model in a collection.
     
     - parameter maxDepth: The number of owner objects to include in the path. 0 => "employees/1", 1 => "companies/4/employees/1", 2 => "regions/9/companies/4/employees/1", etc.
    */
    public func instancePath<T: Model>(for model: T, maxDepth: Int? = nil) -> String? {
        if let collectionPath = self.collectionPath(for: model, maxDepth: maxDepth ?? self.maxPathDepth) {
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
