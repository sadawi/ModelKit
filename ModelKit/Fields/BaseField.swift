//
//  BaseField.swift
//  Pods
//
//  Created by Sam Williams on 1/7/16.
//
//

import Foundation
import StringInflections

public typealias AttributeDictionary = [String: Any]

public enum LoadState {
    case notLoaded
    case incomplete
    case loaded
    case loading
    case error
}

public enum ValidationState:Equatable {
    case unknown
    case invalid([String])
    case valid
    
    public var isInvalid: Bool {
        switch self {
        case .invalid: return true
        default: return false
        }
    }
    
    public var isValid: Bool {
        return self == .valid
    }
}

public func ==(lhs:ValidationState, rhs:ValidationState) -> Bool {
    switch (lhs, rhs) {
    case (.unknown, .unknown): return true
    case (.valid, .valid): return true
    case (let .invalid(leftMessages), let .invalid(rightMessages)): return leftMessages == rightMessages
    default: return false
    }
}

public protocol FieldType: Observable {
    var anyObjectValue: AnyObject? { get set }
    var anyValue: Any? { get set }
    var valueType:Any.Type { get }
    var name: String? { get set }
    var priority: Int? { get set }
    var key: String? { get set }
    var validationState:ValidationState { get }
    var loadState:LoadState { get }
    
    weak var owner: AnyObject? { get set }
    
    var changedAt:Date? { get }
    var updatedAt:Date? { get }
    
    func addValidationError(_ message:String)
    func resetValidationState()
    func validate() -> ValidationState

    func read(from dictionary:AttributeDictionary, in context: ValueTransformerContext)
    func write(to dictionary:inout AttributeDictionary, seenFields:inout [FieldType], in context: ValueTransformerContext)
    
    func merge(from field: FieldType)
}

public extension FieldType {
    func read(from dictionary:AttributeDictionary) {
        self.read(from: dictionary, in: ValueTransformerContext.defaultContext)
    }
    
    public func write(to dictionary:inout AttributeDictionary, in context: ValueTransformerContext=ValueTransformerContext.defaultContext) {
        var seenFields:[FieldType] = []
        self.write(to: &dictionary, seenFields: &seenFields, in: context)
    }
}


let DefaultObserverKey:NSString = "____"

open class BaseField<T>: FieldType, ValueObserver, ValueObservable {
    public typealias ValueType = T
    
    weak public var owner: AnyObject?

    // MARK: - Value transformers

    open var valueTransformers:[String:ValueTransformer<T>] = [:]
    
    /**
     Adds a value transformer (with optional context) for this field.
     
     - parameter importValue: A closure mapping an external value (e.g., a string) to a value for this field.
     - parameter exportValue: A closure mapping a field value to an external value
     - parameter in: A ValueTransformerContext used to identify this transformer. If omitted, will be the default context.
     */
    @discardableResult open func transform(in context: ValueTransformerContext = ValueTransformerContext.defaultContext, importValue:@escaping ValueTransformer<T>.ImportActionType, exportValue:@escaping ValueTransformer<T>.ExportActionType) -> Self {
        
        self.valueTransformers[context.name] = ValueTransformer(importAction: importValue, exportAction: exportValue)
        return self
    }

    /**
     Sets a ValueTransformer for this field.
     
     - parameter transformer: The ValueTransformer to set
     - parameter in: A ValueTransformerContext used to identify this transformer. If omitted, will be the default context.
     */
    @discardableResult open func transform(with transformer:ValueTransformer<T>,
                                           in context:ValueTransformerContext=ValueTransformerContext.defaultContext) -> Self {
        self.valueTransformers[context.name] = transformer
        return self
    }

    open var valueType:Any.Type {
        return T.self
    }
    
    open func defaultValueTransformer(in context: ValueTransformerContext) -> ValueTransformer<T> {
        return SimpleValueTransformer<T>()
    }

    /**
     Finds a value transformer (either in the default transformer context or a specified one) for this field.
     
     Priority:
     - A transformer manually specified on this field (for the specified context)
     - This field's default transformer
     */
    open func valueTransformer(in context: ValueTransformerContext = ValueTransformerContext.defaultContext) -> ValueTransformer<T>? {
        if let transformer = self.valueTransformers[context.name] {
            return transformer
        } else if let transformer = context.transformer(for: T.self) {
            return transformer
        } else {
            return self.defaultValueTransformer(in: context)
        }
    }
    
    // MARK: - 
    
    /**
     Information about whether this field's value has been set (including to nil). 
     A field initialized with a default value will be considered .notLoaded
     */
    open var loadState:LoadState = .notLoaded
    
    /**
     A human-readable name for this field.
     */
    open var name:String?
    
    /**
     Desired position in forms
     */
    open var priority:Int?
    
    /**
     An internal identifier (e.g., for identifying form fields)
     */
    open var key:String?
    
    // MARK:- Value

    /**
     The value contained in this field.  Note: it's always Optional.
     Delegates to setValue/getValue methods.
     */
    public var value:T? {
        set {
            self.setValue(newValue)
        }
        get {
            return self.getValue()
        }
    }
    private var _value: T?
    
    open func getValue() -> T? {
        return _value
    }
    
    /**
     A description of the possible values this field can have.
     The field is guaranteed never to have a non-nil value outside this domain.
     Note: attempting to set a value outside the domain will *not* yield a validation error; the value will either be clamped to the domain or nil.
     */
    open var domain: ValueDomain<T> = ValueDomain()
    
    /**
     Sets the field's domain to an explicit ValueDomain instance
     */
    open func constrain(to domain: ValueDomain<T>) -> Self {
        self.domain = domain
        return self
    }
    
    /**
     Processes an incoming value and transforms it to a suitable value.
     */
    open func constrain(_ value: T?) -> T? {
        if let value = value {
            return self.domain.clamp(value)
        } else {
            return value
        }
    }
    
    open func setValue(_ newValue: T?) {
        let newValue = self.constrain(newValue)
        let oldValue = _value
        _value = newValue
        self.valueUpdated(oldValue: oldValue, newValue: newValue)
    }
    
    open var anyObjectValue:AnyObject? {
        get {
            return self.value as AnyObject?
        }
        set {
            // Always set nil if it's passed in
            if newValue == nil {
                self.value = nil
            }
            // If it's not nil, only set a value if it's the right type
            if let value = newValue as? T {
                self.value = value
            }
        }
    }
    
    open var anyValue:Any? {
        get {
            // It's important to cast to `Any?` rather than `Any`.
            // Casting to `Any` seems to hide the optional in a way that's hard to unwrap.
            return self.value as Any?
        }
        set {
            self.value = newValue as? T
        }
    }
    
    open func valueUpdated(oldValue:T?, newValue: T?) {
        self.loadState = .loaded
        self.validationState = .unknown
        self.updatedAt = Date()
        self.processNewValue(value)
        self.valueUpdatedHandler?(newValue)
        
        if self.isChange(oldValue: oldValue, newValue: newValue) {
            self.changedAt = Date()
            self.notifyObservers(valueChanged: true)
        } else {
            self.notifyObservers(valueChanged: false)
        }
    }
    
    open func isChange(oldValue: T?, newValue: T?) -> Bool {
        return false
    }
    
    open func processNewValue(_ value: T?) {
    }
    
    // MARK: -
    
    internal var valueUpdatedHandler:((T?) -> Void)?
    
    @discardableResult open func valueUpdated(_ handler: @escaping ((T?) -> Void)) -> Self {
        self.valueUpdatedHandler = handler
        return self
    }
    
    
    open var changedAt:Date?
    open var updatedAt:Date?
    
    
    /**
     Initialize a new field.
     */
    public init(value: T? = nil, name: String? = nil, priority: Int? = nil, key: String? = nil) {
        if let value = value {
            self.value = value
        }
        // Ensure we initialize as .notLoaded, even if a value is set.
        self.loadState = .notLoaded
        self.name = name
        self.priority = priority
        self.key = key
    }
    
    // MARK: - Validation
    
    internal var validationRules:[ValidationRule<T>] = []
    
    open  var validationState:ValidationState = .unknown
    
    /**
     Test whether the current field value passes all the validation rules.
     
     - returns: A ValidationState that includes error messages, if applicable.
     */
    open func validate() -> ValidationState {
        var valid = true
        var messages:[String] = []
        for validator in self.validationRules {
            if validator.validate(self.value) == false {
                valid = false
                if let message = validator.message {
                    messages.append(message)
                }
            }
        }
        self.validationState = valid ? .valid : .invalid(messages)
        return self.validationState
    }
    
    open func validateIfNeeded() -> ValidationState {
        if self.validationState == .unknown {
            return self.validate()
        } else {
            return self.validationState
        }
    }
    
    open func resetValidationState() {
        self.validationState = .unknown
    }
    
    open func addValidationError(_ message:String) {
        switch self.validationState {
        case .invalid(var messages):
            messages.append(message)
            self.validationState = .invalid(messages)
        default:
            self.validationState = .invalid([message])
        }
    }
    
    /**
     Adds a validation rule to the field.
     
     - parameter message: A message explaining why validation failed, in the form of a partial sentence (e.g., "must be zonzero")
     - parameter allowNil: Whether nil values should be considered valid
     - parameter test: A closure containing validation logic for an unwrapped field value
     */
    @discardableResult open func require(message:String?=nil, allowNil:Bool=true, test:@escaping ((T) -> Bool)) -> Self {
        let rule = ValidationRule<T>(test: test, message:message, allowNil: allowNil)
        return self.require(rule)
    }
    
    @discardableResult open func requireNotNil() -> Self {
        return self.require(message: "is required", allowNil:false) { T -> Bool in return true }
    }
    
    @discardableResult open func require(_ rule: ValidationRule<T>) -> Self {
        self.validationRules.append(rule)
        return self
    }

    @discardableResult open func require(_ rules: [ValidationRule<T>]) -> Self {
        self.validationRules.append(contentsOf: rules)
        return self
    }
    
    // MARK: - Observation
    
    open var observations = ObservationRegistry<ValueObservation<T>>()
    
    /**
     If a field is registered as a value observer, it will set its own value to the observed new value.
     */
    open func observedValueChanged<ObservableType:ValueObservable>(from oldValue:T?, to newValue:T?, observable:ObservableType?) {
        self.value = newValue
    }
    
    // MARK: - Dictionary values
    
    func key(in context: ValueTransformerContext) -> String? {
        if let key = self.key {
            if let keyCase = context.keyCase {
                return key.to(case: keyCase)
            } else {
                return key
            }
        } else {
            return nil
        }
    }
    
    open func read(from dictionary:AttributeDictionary, in context: ValueTransformerContext) {
        if let key = self.key(in: context), let dictionaryValue = dictionary[key], let transformer = self.valueTransformer(in: context) {
            self.value = transformer.importValue(dictionaryValue, in: context)
        }
    }
    
    open func write(to dictionary: inout AttributeDictionary, seenFields: inout [FieldType], in context: ValueTransformerContext = .defaultContext) {
        if let key = self.key(in: context) {
            if seenFields.contains(where: {$0 === self}) {
                self.writeSeenValue(to: &dictionary, seenFields: &seenFields, key: key, in: context)
            } else {
                seenFields.append(self)
                self.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key, in: context)
            }
        }
    }
    
    open func writeUnseenValue(to dictionary: inout AttributeDictionary, seenFields: inout [FieldType], key: String, in context: ValueTransformerContext = .defaultContext) {
        if let transformer = self.valueTransformer(in: context) {
            dictionary[key] = transformer.exportValue(self.value, in: context)
        }
    }
    
    open func writeSeenValue(to dictionary: inout AttributeDictionary, seenFields: inout [FieldType], key: String, in context: ValueTransformerContext = .defaultContext) {
        self.writeUnseenValue(to: &dictionary, seenFields: &seenFields, key: key, in: context)
    }
    
    // MARK: - Transformers
    
    open var defaultValueTransformerContext: ValueTransformerContext {
        return ValueTransformerContext.defaultContext
    }
    
    // MARK: - Merge
    
    // TODO: throw?
    public func copyValue(from field: FieldType, copyTimestamps: Bool = false) {
        guard let field = field as? BaseField<ValueType> else { return }
        self.copyValue(from: field, copyTimestamps: copyTimestamps)
    }

    public func copyValue(from field: BaseField<T>, copyTimestamps: Bool = false) {
        self.value = field.value
        if copyTimestamps {
            self.updatedAt = field.updatedAt
            self.changedAt = field.changedAt
        }
    }
    
    /**
     Checks whether this field's value should be considered newer than another field's value.
     A nil timestamp is always considered old.
     If neither has a timestamp, returns false.
     */
    public func isNewer(than field: FieldType) -> Bool {
        if let otherUpdatedAt = field.updatedAt {
            if let selfUpdatedAt = self.updatedAt {
                // both have timestamps
                return selfUpdatedAt.compare(otherUpdatedAt) == .orderedDescending
            } else {
                // self does not have timestamp, other has timestamp
                return false
            }
        } else {
            if self.updatedAt != nil {
                // self has timestamp, other does not
                return true
            } else {
                // neither has timestamps.
                return false
            }
        }
    }
    
    /**
     Copies the value from `field` iff it is newer than self. 
     If neither has a timestamp, nothing will happen.
     */
    public func merge(from field: FieldType) {
        if let field = field as? BaseField<ValueType> {
            if field.loadState == .loaded && field.isNewer(than: self) {
                self.copyValue(from: field)
            }
        }
    }
}

extension BaseField where T: Equatable {
    /**
     Sets the field's domain to a list of values.
     */
    open func constrain(to domainValues: [T]) -> Self {
        return self.constrain(to: DiscreteValueDomain(domainValues))
    }
}


extension BaseField where T: Comparable {
    /**
     Sets the field's domain to a continuous range domain.
     */
    open func constrain(to domainValues: ClosedRange<T>) -> Self {
        return self.constrain(to: RangeValueDomain(domainValues))
    }
}
