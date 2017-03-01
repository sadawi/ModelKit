//
//  Model.swift
//  APIKit
//
//  Created by Sam Williams on 11/7/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public typealias Identifier = String
public typealias Interface = [String:FieldType]

open class ModelValueTransformerContext: ValueTransformerContext {
    /**
     An object that is responsible for keeping track of canonical instances
     */
    public var registry:ModelRegistry? = MemoryRegistry()
}

public extension ValueTransformerContext {
    static let defaultModelContext = ModelValueTransformerContext(name: "model")
}

open class Model: NSObject, NSCopying, Observable {
    /**
     The class to instantiate, based on a dictionary value.  For example, your dictionary might include a "type" string.
     
     Whatever class you attempt to return must be cast to T.Type, which is inferred to be Self.
     
     In other words, if you don't return a subclass, it's likely that you'll silently get an instance of
     whatever class defines this method.
     */
    open class func instanceClass<T>(for dictionaryValue: AttributeDictionary) -> T.Type? {
        return self as? T.Type
    }
    
    private static var prototypes = TypeDictionary<Model>()
    
    private static func prototype<T: Model>(for type: T.Type) -> T {
        if let existing = prototypes[type] as? T {
            return existing
        } else {
            let prototype = type.init()
            prototypes[type] = prototype
            return prototype
        }
    }
    
    /**
     Attempts to instantiate a new object from a dictionary representation of its attributes.
     If a registry is set, will attempt to reuse the canonical instance for its identifier
     
     - parameter dictionaryValue: The attributes
     - parameter configure: A closure to configure a deserialized model, taking a Bool flag indicating whether it was newly instantiated (vs. reused from registry)
     */
    open class func from(dictionaryValue:AttributeDictionary, in context: ValueTransformerContext = .defaultModelContext, configure:((Model,Bool) -> Void)?=nil) -> Self? {
        var instance = (self.instanceClass(for: dictionaryValue) ?? self).init()
        (instance as Model).readDictionaryValue(dictionaryValue, in: context)
        
        var isNew = true
        
        if let modelContext = context as? ModelValueTransformerContext, let registry = modelContext.registry {
            // If we have a canonical object for this id, swap it in
            if let canonical = registry.canonicalModel(for: instance) {
                isNew = false
                instance = canonical
                (instance as Model).readDictionaryValue(dictionaryValue, in: modelContext)
            } else {
                isNew = true
                registry.didInstantiate(instance)
            }
        }
        configure?(instance, isNew)
        return instance
        
    }
    
    public required override init() {
        super.init()
        self.buildFields()
        self.afterInit()
    }
    
    open func afterInit()     { }
    open func afterCreate()   { }
    open func beforeSave()    { }
    open func afterDelete()   { }

    /**
     Returns a unique instance of this class for an identifier. If a matching instance is already registered, returns that. Otherwise, returns a new instance.
     */
    open class func with(identifier: Identifier, in context: ModelValueTransformerContext) -> Self {
        let instance = self.init()
        instance.identifier = identifier
        if let registry = context.registry {
            if let canonical = registry.canonicalModel(for: instance) {
                return canonical
            } else {
                registry.didInstantiate(instance)
            }
        }
        return instance
    }
    
    /**
     Returns a canonical instance corresponding to this instance.
     */
    open func canonicalInstance(in context: ModelValueTransformerContext) -> Self {
        return context.registry?.canonicalModel(for: self) ?? self
    }
    
    /**
     Creates a clone of this model.  It won't exist in the registry.
     */
    open func copy(with zone: NSZone?) -> Any {
        return type(of: self).from(dictionaryValue: self.dictionaryValue())!
    }

    
    /**
     Which field should be treated as the identifier?
     If all the models in your system have the same identifier field (e.g., "id"), you'll probably want to just put that in your
     base model class.
     */
    open var identifierField: FieldType? {
        return nil
    }
    
    /**
     Attempts to find the identifier as a String or Int, and cast it to an Identifier (aka String)
     (because it's useful to have an identifier with known type!)
     */
    open var identifier:Identifier? {
        get {
            let value = self.identifierField?.anyObjectValue
            
            if let value = value as? Identifier {
                return value
            } else if let value = value as? Int {
                return String(value)
            } else {
                return nil
            }
        }
        set {
            if let id = newValue {
                if let stringField = self.identifierField as? Field<String> {
                    stringField.value = id
                } else if let intField = self.identifierField as? Field<Int> {
                    intField.value = Int(id)
                }
            }
        }
    }
    
    // TODO: permissions
    open var editable:Bool = true
    
    open var loadState: LoadState = .loaded
    
    /**
     Removes all data from this instance except its identifier, and sets the loadState to .incomplete.
     */
    open func unload() {
        for (_, field) in self.fields where field.key != self.identifierField?.key {
            field.anyValue = nil
        }
        self.loadState = .incomplete
    }
    
    open class var name:String {
        get {
            if let name = NSStringFromClass(self).components(separatedBy: ".").last {
                return name
            } else {
                return "Unknown"
            }
        }
    }
    
    open func cascadeDelete(_ cascade: ((Model)->Void), seenModels: inout Set<Model>) {
        self.visitAllFields(action: { field in
            if let modelField = field as? ModelFieldType , modelField.cascadeDelete {
                if let model = modelField.anyObjectValue as? Model {
                    cascade(model)
                } else if let models = modelField.anyObjectValue as? [Model] {
                    for model in models {
                        cascade(model)
                    }
                }
            }
        }, seenModels: &seenModels)
    }
    
    /**
     Finds a field (possibly belonging to a child model) for a key path, specified as a list of strings.
     */
    open func field(at path:FieldPath) -> FieldType? {
        var path = path
        
        guard let firstComponent = path.shift() else { return nil }
        
        let fields = self.fields
        
        if let firstField = fields[firstComponent] {
            if path.length == 0 {
                // No more components.  Just return the field
                return firstField
            } else if let firstValue = firstField.anyValue as? Model {
                // There are more components remaining, and we can keep traversing key paths
                return firstValue.field(at: path)
            }
        }
        return nil
    }
    
    /**
     Finds a field (possibly belonging to a child model) for a key path, specified as a single string.
     The string will be split using `componentsForKeyPath(_:)`.
     */
    open func field(at path:String) -> FieldType? {
        return field(at: self.fieldPath(path))
    }
    
    /**
     Splits a field keypath into an array of field names to be traversed.
     For example, "address.street" might be split into ["address", "street"]
     
     To change the default behavior, you'll probably want to subclass.
     */
    open func fieldPath(_ path:String) -> FieldPath {
        return FieldPath(path, separator: ".")
    }
    
    open func fieldPath(for field: FieldType) -> FieldPath? {
        if let key = field.key {
            return [key]
        } else {
            return nil
        }
    }
    
    public var fields = Interface()
    
    /**
     Which fields should we include in the dictionaryValue?
     By default, includes all of them.
     */
    open func defaultFieldsForDictionaryValue() -> [FieldType] {
        return Array(self.fields.values)
    }
    
    /**
     Look at the instance's fields, do some introspection and processing.
     */
    internal func buildFields() {
        for (key, field) in self.staticFields {
            if field.key == nil {
                field.key = key
            }
            self.initializeField(field)
            self.fields[key] = field
        }
    }
    
    public static func <<(object: Model, field: FieldType) {
        object.add(field: field)
    }
    
    public func add(field: FieldType) {
        guard let key = field.key else { return }

        self.initializeField(field)
        self.fields[key] = field
    }
    
    open subscript (key: String) -> Any? {
        get {
            return self[FieldPath(key)]
        }
        set {
            return self[FieldPath(key)] = newValue
        }
    }
    
    open subscript (keyPath: FieldPath) -> Any? {
        get {
            guard let field = self.field(at: keyPath) else { return nil }
            return field.anyValue
        }
        set {
            guard let field = self.field(at: keyPath) else { return }
            field.anyValue = newValue
        }
    }

    lazy open var staticFields:Interface = {
       return self.buildStaticFields()
    }()

    /**
     Builds a mapping of keys to fields.  Keys are either the field's `key` property (if specified) or the property name of the field.
     This can be slow, since it uses reflection.  If you find this to be a performance bottleneck, consider overriding the `staticFields` var
     with an explicit mapping of keys to fields.
     */
    private func buildStaticFields() -> Interface {
        var result = Interface()
        let mirror = Mirror(reflecting: self)
        mirror.eachChild { child in
            if let label = child.label, let value = child.value as? FieldType {
                // If the field has its key defined, use that; otherwise fall back to the property name.
                let key = value.key ?? label
                result[key] = value
            }
        }
        
        return result
    }
    

    /**
     Performs any model-level field initialization your class may need, before any field values are set.
     */
    open func initializeField(_ field:FieldType) {
        field.owner = self
    
        // Can't add observeration blocks that take values, since the FieldType protocol doesn't know about the value type
        field.addObserver { [weak self] in
            var seen = Set<Model>()
            self?.fieldValueChanged(field, at: [], seen: &seen)
        }

        // If it's a model field, add a deep observer for changes on its value.
        if let modelField = field as? ModelFieldType {
            modelField.addModelObserver(self, updateImmediately: false) { [weak self] model, fieldPath, seen in
                print(fieldPath)
                self?.fieldValueChanged(field, at: fieldPath, seen: &seen)
            }
        }
        
    }
    
    open func fieldValueChanged(_ field: FieldType, at relativePath: FieldPath, seen: inout Set<Model>) {
        // Avoid cycles
        guard !seen.contains(self) else { return }
        
        if let path = self.fieldPath(for: field) {
            let fullPath = path.appending(path: relativePath)
            seen.insert(self)
            self.notifyObservers(path: fullPath, seen: &seen)
        }
    }
    
    public func visitAllFields(recursive:Bool = true, action:((FieldType) -> Void)) {
        var seenModels: Set<Model> = Set()
        self.visitAllFields(recursive: recursive, action: action, seenModels: &seenModels)
    }
    
    private func visitAllFields(recursive:Bool = true, action:((FieldType) -> Void), seenModels:inout Set<Model>) {
        guard !seenModels.contains(self) else { return }
        
        seenModels.insert(self)
        
        for (_, field) in self.fields {
            
            action(field)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFields(recursive: recursive, action: action, seenModels: &seenModels)
                } else if let values = field.anyObjectValue as? NSArray {
                    for value in values {
                        if let model = value as? Model {
                            model.visitAllFields(recursive: recursive, action: action, seenModels: &seenModels)
                        }
                    }
                }
            }
        }
    }

    public func visitAllFieldValues(recursive:Bool = true, action:((Any?) -> Void)) {
        var seenModels: Set<Model> = Set()
        self.visitAllFieldValues(recursive: recursive, action: action, seenModels: &seenModels)
}

    private func visitAllFieldValues(recursive:Bool = true, action:((Any?) -> Void), seenModels:inout Set<Model>) {
        guard !seenModels.contains(self) else { return }

        seenModels.insert(self)

        for (_, field) in self.fields {
            
            action(field.anyValue)
            
            if recursive {
                if let value = field.anyObjectValue as? Model {
                    value.visitAllFieldValues(recursive: recursive, action: action, seenModels: &seenModels)
                } else if let value = field.anyValue, let values = value as? NSArray {
                    // I'm not sure why I can't cast to [Any]
                    // http://stackoverflow.com/questions/26226911/how-to-tell-if-a-variable-is-an-array
                    
                    for value in values {
                        action(value)
                        if let modelValue = value as? Model {
                            modelValue.visitAllFieldValues(recursive: recursive, action: action, seenModels: &seenModels)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Converts this object to its dictionary representation, optionally limited to a subset of its fields.  By default, it will 
     export all fields in `defaultFieldsForDictionaryValue` (which itself defaults to all fields) that have been loaded.
     
     - parameter fields: An array of field objects (belonging to this model) to be included in the dictionary value.
     - parameter in: A value transformer context, used to obtain the correct value transformer for each field.
     - parameter includeField: A closure determining whether a field should be included in the result.  By default, it will be included iff its state is .Set (i.e., it has been explicitly set since it was loaded)
     */
    open func dictionaryValue(fields:[FieldType]?=nil, in context: ValueTransformerContext = .defaultContext, includeField: ((FieldType) -> Bool)?=nil) -> AttributeDictionary {
        var seenFields:[FieldType] = []
        var includeField = includeField
        if includeField == nil {
            includeField = { (field:FieldType) -> Bool in field.loadState == LoadState.loaded }
        }
        return self.dictionaryValue(fields: fields, seenFields: &seenFields, in: context, includeField: includeField)
    }
    
    internal func dictionaryValue(fields:[FieldType]? = nil, seenFields: inout [FieldType], in context: ValueTransformerContext = .defaultContext, includeField: ((FieldType) -> Bool)? = nil) -> AttributeDictionary {
        let fields = fields ?? self.defaultFieldsForDictionaryValue()
        
        var result:AttributeDictionary = [:]
        let include = fields
        for (_, field) in self.fields {
            if include.contains(where: { $0 === field }) && includeField?(field) != false {
                field.write(to: &result, seenFields: &seenFields, in: context)
            }
        }
        return result
    }
    
    /**
     Read field values from a dictionary representation.  If a field's key is missing from the dictionary,
     but the field is included in the fields to be imported, its value will be set to nil.
     
     - parameter dictionaryValue: The dictionary representation of this model's new field values
     - parameter fields: An array of field objects whose values are to be found in the dictionary
     - parameter in: A value transformer context, used to obtain the correct value transformer for each field
     */
    open func readDictionaryValue(_ dictionaryValue: AttributeDictionary, fields:[FieldType]?=nil, in context: ValueTransformerContext=ValueTransformerContext.defaultContext) {
        let fields = (fields ?? self.defaultFieldsForDictionaryValue())
        for (_, field) in self.fields {
            if fields.contains(where: { $0 === field }) {
                field.read(from: dictionaryValue, in: context)
            }
        }
    }
    
    /**
     Finds all values that are incompletely loaded (i.e., a model instantiated from just a foreign key)
     */
    open func incompleteChildModels(recursive:Bool = false) -> [Model] {
        var results:[Model] = []
        self.visitAllFieldValues(recursive: recursive) { value in
            if let model = value as? Model, model.loadState == .incomplete {
                results.append(model)
            }
        }
        return results
    }
    
    /**
     All models related with foreignKey fields
     */
    open func foreignKeyModels() -> [Model] {
        var results:[Model] = []
        
        self.visitAllFields { field in
            if let modelField = field as? ModelFieldType , modelField.foreignKey == true {
                if let value = modelField.anyObjectValue as? Model {
                    results.append(value)
                } else if let values = modelField.anyObjectValue as? [Model] {
                    for value in values {
                        results.append(value)
                    }
                }
            }
        }
        return results
    }
    
    // MARK: Validation
    
    /**
     Adds a validation error message to a field identified by a key path.
     
     - parameter keyPath: The path to the field (possibly belonging to a child model) that has an error.
     - parameter message: A description of what's wrong.
     */
    open func addError(at path:FieldPath, message:String) {
        if let field = self.field(at: path) {
            field.addValidationError(message)
        }
    }
    
    /**
     Test whether this model passes validation.  All fields will have their validation states updated.
     
     By default, related models are not themselves validated.  Use the `requireValid()` method on those fields for deeper validation.
     */
    open func validate() -> ValidationState {
        self.resetValidationState()
        var messages: [String] = []
        
        self.visitAllFields(recursive: false) { field in
            if case .invalid(let fieldMessages) = field.validate() {
                messages.append(contentsOf: fieldMessages)
            }
        }
        
        if messages.count == 0 {
            return .valid
        } else {
            return .invalid(messages)
        }
    }
    
    open func resetValidationState() {
        self.visitAllFields { $0.resetValidationState() }
    }
    
    // MARK: - Merging
    
    /**
     Merges field values from another model.
     Fields are matched by key, and compared using `updatedAt` timestamps; the newer value wins.
     */

    public func merge(from model: Model) {
        self.merge(from: model, include: Array(self.fields.values))
    }

    public func merge(from model: Model, exclude excludedFields: [FieldType]) {
        self.merge(from: model) { field in
            !excludedFields.contains { $0 === field }
        }
    }
    
    public func merge(from model: Model, include condition: ((FieldType)->Bool)) {
        let fields = self.fields.values.filter(condition)
        merge(from: model, include: fields)
    }

    open func merge(from model: Model, include includedFields: [FieldType]) {
        let otherFields = model.fields
        
        for field in includedFields {
            if let key = field.key, let otherField = otherFields[key] {
                field.merge(from: otherField)
            }
        }
    }
    
    // MARK: - 
    /**
     A object to be used as a standard prototypical instance of this class, for the purpose of accessing fields, etc.
     It is reused when possible.
     */
    public class func prototype() -> Self {
        return Model.prototype(for: self)
    }
    
    open var observations = ObservationRegistry<ModelObservation>()

    // MARK: - Observations
    
    @discardableResult public func addObserver(_ observer: AnyObject?=nil, for fieldPath: FieldPath?=nil, updateImmediately: Bool = false, action:@escaping ModelObservation.Action) -> ModelObservation {
        let observation = ModelObservation(fieldPath: fieldPath, action: action)
        self.observations.add(observation, for: observer)
        return observation
    }
    
    @discardableResult public func addObserver(updateImmediately: Bool, action:@escaping ((Void) -> Void)) {
        self.addObserver(updateImmediately: updateImmediately) { _, _, _ in
            action()
        }
    }

    
    public func notifyObservers(path: FieldPath, seen: inout Set<Model>) {
        // Changing a value at a path implies a change of all child paths. Notify accordingly.
        var path = path
        path.isPrefix = true
        
        self.observations.forEach { observation in
            observation.perform(model: self, fieldPath: path, seen: &seen)
        }
    }
    

    public func removeObserver(_ observer: AnyObject) {
        self.observations.remove(for: observer)
    }

    public func removeAllObservers() {
        self.observations.clear()
    }

}
