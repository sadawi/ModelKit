//
//  RemoteServer.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Alamofire
import PromiseKit

public enum RemoteModelStoreError: Error {
    case unknownError(message: String)
    case deserializationFailure
    case serializationFailure
    case invalidResponse
    case noModelPath(model: Model)
    case noModelCollectionPath(modelClass: Model.Type)
    
    var description: String {
        switch(self) {
        case .deserializationFailure:
            return "Could not deserialize model"
        case .serializationFailure:
            return "Could not serialize"
        case .invalidResponse:
            return "Invalid response value"
        case .noModelPath(let model):
            return "No path for model of type \(type(of: model))"
        case .unknownError(let message):
            return message
        case .noModelCollectionPath(let modelClass):
            return "No path for model collection of type \(modelClass)"
        }
    }
}

open class RemoteModelStore: ModelStore, ListableModelStore {
    open var baseURL:URL
    open var delegate:ModelStoreDelegate?
    open var router = RESTRouter()
    
    public init(baseURL:URL) {
        self.baseURL = baseURL
    }
    
    /**
     Creates a closure that deserializes a model and returns a Promise.
     Useful in promise chaining as an argument to .then
     
     - parameter modelClass: The Model subclass to be instantiated
     - returns: A Promise yielding a Model instance
     */
    open func instantiateModel<T:Model>(_ modelClass:T.Type) -> ((Response<AttributeDictionary>) -> Promise<T>){
        return { (response:Response<AttributeDictionary>) in
            if let data = response.data, let model = self.deserializeModel(modelClass, parameters: data) {
                return Promise(value: model)
            } else {
                return Promise(error: RemoteModelStoreError.deserializationFailure)
            }
        }
    }
    
    open func instantiateModels<T:Model>(_ modelClass:T.Type) -> ((Response<[AttributeDictionary]>) -> Promise<[T]>) {
        return { (response:Response<[AttributeDictionary]>) in
            // TODO: any of the individual models could fail to deserialize, and we're just silently ignoring them.
            // Not sure what the right behavior should be.
            if let values = response.data {
                let models = values.map { value -> T? in
                    let model:T? = self.deserializeModel(modelClass, parameters: value)
                    return model
                    }.flatMap{$0}
                return Promise(value: models)
            } else {
                return Promise(value: [])
            }
        }
    }
    
    // MARK: - Helper methods that subclasses might want to override
    
    fileprivate func url(path:String) -> URL {
        return self.baseURL.appendingPathComponent(path)
    }
    
    open func defaultHeaders() -> [String:String] {
        return [:]
    }
    
    open func formatPayload(_ payload:AttributeDictionary) -> AttributeDictionary {
        return payload
    }
    
    open func serializeModel(_ model:Model, fields:[FieldType]?=nil) -> AttributeDictionary {
        return model.dictionaryValue(fields: fields, explicitNull: true)
    }
    
    open func deserializeModel<T:Model>(_ modelClass:T.Type, parameters:AttributeDictionary) -> T? {
        // TODO: would rather use value transformer here instead, but T is Model instead of modelClass and it doesn't get deserialized properly
        //        return ModelValueTransformer<T>().importValue(parameters)
        let model = modelClass.from(dictionaryValue: parameters)
        model?.loadState = .loaded
        return model
    }
    
    open func handleError(_ error:Error, model:Model?=nil) {
        // Override
    }
    
    /**
     Retrieves the data payload from the Alamofire response and attempts to cast it to the correct type.
     
     Override this to allow for an intermediate "data" key, for example.
     
     Note: T is only specified by type inference from the return value.
     Note: errors aren't processed from the response.  Subclasses should handle that for a specific API response format.
     
     - parameter apiResponse: The JSON response object from an Alamofire request
     - returns: A Response object with its payload cast to the specified type
     */
    open func constructResponse<T>(_ apiResponse:Alamofire.DataResponse<Any>) -> Response<T>? {
        let response = Response<T>()
        response.data = apiResponse.result.value as? T
        return response
    }
    
    
    // MARK: - Generic requests
    
    // TODO: update for Alamofire 4 ParameterEncoding protocol
//    open func nestedParameterEncoding(method:Alamofire.HTTPMethod) -> ParameterEncoding {
//        return ParameterEncoding.custom({ (request:URLRequestConvertible, parameters:[String: AnyObject]?) -> (NSMutableURLRequest, NSError?) in
//            let request = request as? NSMutableURLRequest ?? NSMutableURLRequest()
//            if let parameters = parameters, let url = request.URL {
//                if method == .GET {
//                    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
//                    components?.query = ParameterEncoder().encodeParameters(parameters)
//                    request.URL = components?.URL
//                } else {
//                    request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
//                    request.HTTPBody = ParameterEncoder(includeNullValues: true).encodeParameters(parameters).dataUsingEncoding(NSUTF8StringEncoding)
//                }
//            }
//            return (request, nil)
//        })
//    }
    
    open func encodingForMethod(_ method: Alamofire.HTTPMethod) -> ParameterEncoding {
        return URLEncoding()
//        return self.nestedParameterEncoding(method: method)
    }
    
    /**
     A placeholder method in which you can attempt to restore your session (refreshing your oauth token, for example) before each request.
     */
    open func restoreSession() -> Promise<Void> {
        return Promise<Void>(value: ())
    }
    
    /**
     The core request method, basically a Promise wrapper around an Alamofire.request call
     Parameterized by the T, the expected data payload type (typically either a dictionary or an array of dictionaries)
     
     TODO: At the moment T is only specified by type inference from the return value, which is awkward since it's a promise.
     Consider specifying as a param.
     
     - returns: A Promise parameterized by the data payload type of the response
     */
    open func request<T>(
        _ method: Alamofire.HTTPMethod,
        path: String,
        parameters: AttributeDictionary?=nil,
        headers: [String:String]=[:],
        encoding: ParameterEncoding?=nil,
        model: Model?=nil,
        timeoutInterval: TimeInterval?=nil,
        cachePolicy: NSURLRequest.CachePolicy?=nil,
        requireSession: Bool = true
        ) -> Promise<Response<T>> {
        
        let url = self.url(path: path)
        let encoding = encoding ?? self.encodingForMethod(method)
        
        let action = { () -> Promise<Response<T>> in
            return Promise { fulfill, reject in
                
                // Compute headers *after* the session has been restored.
                let headers = self.defaultHeaders() + headers
                
                // Manually recreating what Alamofire.request does so we have access to the URLRequest object:
                var mutableRequest = URLRequest(url: url)
                for (field, value) in headers {
                    mutableRequest.setValue(value, forHTTPHeaderField: field)
                }
                if let timeoutInterval = timeoutInterval {
                    mutableRequest.timeoutInterval = timeoutInterval
                }
                if let cachePolicy = cachePolicy {
                    mutableRequest.cachePolicy = cachePolicy
                }
                mutableRequest.httpMethod = method.rawValue
                
                
                guard let encodedRequest = try? encoding.encode(mutableRequest, with: parameters) else { reject(RemoteModelStoreError.serializationFailure); return }
                
                Alamofire.request(encodedRequest).responseJSON { response in
                    switch response.result {
                    case .success:
                        if let value:Response<T> = self.constructResponse(response) {
                            if let error=value.error {
                                // the request might have succeeded, but we found an error when constructing the Response object
                                self.handleError(error, model:model)
                                reject(error)
                            } else {
                                fulfill(value)
                            }
                        } else {
                            let error = RemoteModelStoreError.invalidResponse
                            self.handleError(error)
                            reject(error)
                        }
                    case .failure(let error):
                        self.handleError(error as Error, model:model)
                        reject(error)
                    }
                }
            }
        }
        
        if requireSession {
            return self.restoreSession().then(on: .global(), execute: action)
        } else {
            return action()
        }
    }
    
    // MARK: - CRUD operations (ModelStore protocol methods)
    
    open func create<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T> {
        return self.create(model, fields: fields, parameters: nil)
    }
    
    open func create<T:Model>(_ model: T, fields: [FieldType]?, parameters: [String: AnyObject]?) -> Promise<T> {
        model.resetValidationState()
        model.beforeSave()
        
        var requestParameters = self.formatPayload(self.serializeModel(model, fields: fields))
        if let parameters = parameters {
            for (k,v) in parameters {
                requestParameters[k] = v
            }
        }
        
        // See MemoryModelStore for an explanation [1]
        let modelModel = model as Model
        
        if let collectionPath = self.router.collectionPath(for: model) {
            return self.request(.post, path: collectionPath, parameters: requestParameters, model:model).then(on: .global(), execute: self.instantiateModel(type(of: modelModel))).then(on: .global()) { model in
                model.afterCreate()
                return Promise(value: model as! T)
            }
        }else {
            return Promise(error: RemoteModelStoreError.noModelCollectionPath(modelClass: type(of: modelModel)))
        }
    }
    
    open func update<T:Model>(_ model: T, fields: [FieldType]?) -> Promise<T> {
        return self.update(model, fields: fields, parameters: nil)
    }
    
    open func update<T:Model>(_ model: T, fields: [FieldType]?, parameters: [String: AnyObject]?) -> Promise<T> {
        model.resetValidationState()
        model.beforeSave()
        
        let modelModel = model as Model
        
        if let path = self.router.instancePath(for: model) {
            var requestParameters = self.formatPayload(self.serializeModel(model, fields: fields))
            if let parameters = parameters {
                for (k,v) in parameters {
                    requestParameters[k] = v
                }
            }
            return self.request(.patch, path: path, parameters: requestParameters, model:model).then(on: .global(), execute: self.instantiateModel(type(of: modelModel))).then(on: .global()) { model -> Promise<T> in
                // Dancing around to get the type inference to work
                return Promise<T>(value: model as! T)
            }
        } else {
            return Promise(error: RemoteModelStoreError.noModelPath(model: model))
        }
    }
    
    open func delete<T:Model>(_ model: T) -> Promise<T> {
        if let path = self.router.instancePath(for: model) {
            return self.request(.delete, path: path).then(on: .global()) { (response:Response<T>) -> Promise<T> in
                model.afterDelete()
                return Promise(value: model)
            }
        } else {
            return Promise(error: RemoteModelStoreError.noModelPath(model: model))
        }
    }
    open func lookup<T: Model>(_ modelClass:T.Type, identifier:String) -> Promise<T> {
        return self.lookup(modelClass, identifier: identifier, parameters: nil)
    }
    
    open func lookup<T: Model>(_ modelClass:T.Type, identifier:String, parameters: [String: AnyObject]?) -> Promise<T> {
        let model = modelClass.init() as T
        model.identifier = identifier
        if let path = self.router.instancePath(for: model) {
            return self.read(modelClass, path: path)
        } else {
            return Promise(error: RemoteModelStoreError.noModelPath(model: model))
        }
    }
    
    /**
     Reads a single model from the specified path.
     */
    open func read<T: Model>(_ modelClass: T.Type, path: String, parameters: [String: AnyObject]?=nil) -> Promise<T> {
        return self.request(.get, path: path, parameters: parameters).then(on: .global(), execute: self.instantiateModel(modelClass))
    }
    
    open func refresh<T:Model>(_ model:T, parameters:[String: AnyObject]?=nil) -> Promise<T> {
        if let identifier = model.identifier {
            return self.lookup(T.self, identifier: identifier, parameters: parameters)
        } else {
            return Promise(error: RemoteModelStoreError.noModelPath(model: model))
        }
    }
    
    open func list<T: Model>(_ modelClass:T.Type) -> Promise<[T]> {
        return self.list(modelClass, parameters: nil)
    }
    
    /**
     Retrieves a list of models, with customization of the request path and parameters.
     
     - parameter modelClass: The model class to instantiate
     - parameter path: An optional path.  Defaults to modelClass.path
     - parameter parameters: Request parameters to pass along in the request.
     */
    open func list<T: Model>(_ modelClass:T.Type, path:String?=nil, parameters:[String: AnyObject]?) -> Promise<[T]> {
        if let collectionPath = path ?? self.router.path(to: modelClass) {
            return self.request(.get, path: collectionPath, parameters: parameters).then(on: .global(), execute: self.instantiateModels(modelClass))
        } else {
            return Promise(error: RemoteModelStoreError.noModelCollectionPath(modelClass: modelClass))
        }
    }
    
}
