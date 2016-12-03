//
//  Server.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation
import PromiseKit

let ModelStoreErrorDomain = "ModelStore"

public protocol ListableModelStore {
    /**
     Retrieves a list of all models of the specified type.
     */
    func list<T: Model>(_ modelClass:T.Type) -> Promise<[T]>
}

public protocol ModelStore: ListableModelStore {
    /**
     Inserts a record.  May give the object an identifier.
     // TODO: Decide on strict id semantics.  Do we leave an existing identifier alone, or replace it with a new one?
     The returned object should be a new instance, different from the provided one.
     */
    func create<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T>
    
    /**
     Updates an existing record
     */
    func update<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T>
    
    /**
     Deletes a record.
     */
    func delete<T:Model>(_ model:T) -> Promise<T>
    
    /**
     Retrieves a record with the specified identifier.  The Promise should fail if the record can't be found.
     */
    func lookup<T: Model>(_ modelClass:T.Type, identifier:String) -> Promise<T>
    
    var delegate:ModelStoreDelegate? { get set }
}

public protocol ClearableModelStore {
    /**
     Removes all stored instances of a model class, without fetching them.
     */
    func deleteAll<T: Model>(_ modelClass:T.Type) -> Promise<Void>
    func deleteAll() -> Promise<Void>
}

public extension ModelStore {
    /**
     Determines whether a model has been persisted to this data store.
     
     This version is very dumb and just checks for the presence of an identifier.
     But the signature is Promise-based, so a ModelStore implementation might actually do something asynchronous here.
     */
    public func containsModel(_ model:Model) -> Promise<Bool> {
        return Promise(value: model.identifier != nil)
    }
    
    func create<T:Model>(_ model:T) -> Promise<T> {
        return self.create(model, fields: nil)
    }
    
    public func update<T:Model>(_ model: T) -> Promise<T> {
        return self.update(model, fields: nil)
    }

    
    /**
     Upsert.  Creates a new record or updates an existing one, depending on whether we think it's been persisted.
     */
    public func save<T: Model>(_ model:T, fields:[FieldType]?=nil) -> Promise<T> {
        return self.containsModel(model).then(on: .global()) { (result:Bool) -> Promise<T> in
            if result {
                return self.update(model, fields: fields)
            } else {
                return self.create(model, fields: fields)
            }
        }
    }
}

func <<(left:ModelStore, right:Model) -> Promise<Model> {
    return left.save(right)
}

