//
//  Observable.swift
//  Pods
//
//  Created by Sam Williams on 1/5/16.
//
//

import Foundation

/**
 An object that has a single observable value and can register observers to be notified when that value changes.
 
 Your class is responsible for calling `self.notifyObservers()` when appropriate.
 
 Note: The only reason this is a class protocol is that marking its methods as "mutating" seemed to cause segfaults!
 */
public protocol ValueObservable: Observable {
    associatedtype ObservedValueType
    var value: ObservedValueType? { get set }
    var observations: ObservationRegistry<ValueObservation<ObservedValueType>> { get }
}

public extension ValueObservable {
    /**
     Registers a value change observer.
     
     - parameter observer: an Observer object that will receive change notifications
     */
    @discardableResult public func addObserver<U:ValueObserver>(_ observer:U, requiresChange: Bool = true, updateImmediately: Bool = false) -> U where U.ObservedValueType==ObservedValueType {
        let observation = ValueObservation<ObservedValueType>()
        observation.requiresChange = requiresChange
        observation.action = { (oldValue:ObservedValueType?, newValue:ObservedValueType?) -> Void in
            observer.observedValueChanged(from: oldValue, to: newValue, observable:self)
        }
        if updateImmediately {
            observation.perform(oldValue: nil, newValue: self.value)
        }
        self.observations.add(observation, for: observer)
        return observer
    }

    @discardableResult public func addObserver(updateImmediately: Bool, action:@escaping ((Void) -> Void)) {
        return self.addObserver(requiresChange: true, updateImmediately: updateImmediately, action: action)
    }
    
    @discardableResult public func addObserver(requiresChange: Bool, updateImmediately: Bool, action:@escaping ((Void) -> Void)) {
        self.addObserver(requiresChange: requiresChange) { (oldValue: ObservedValueType?, newValue: ObservedValueType?) in
            action()
        }
    }

    /**
     Registers a value change action.
     
     - parameter action: A closure to be run when the value changes
     */
    @discardableResult public func addObserver(requiresChange: Bool = true, updateImmediately: Bool = false, action:@escaping ((ObservedValueType?, ObservedValueType?) -> Void)) -> ValueObservation<ObservedValueType> {
        let observation = self.createClosureObservation(requiresChange: requiresChange, action: action)
        if updateImmediately {
            observation.perform(oldValue: nil, newValue: self.value)
        }
        self.observations.add(observation)
        return observation
    }

    /**
     Registers a value change action, along with a generic owner.
     
     - parameter owner: The observation owner, used only as a key for registering the action
     - parameter action: A closure to be run when the value changes
     */
    @discardableResult public func addObserver<U: AnyObject>(_ owner:U, requiresChange: Bool = true, updateImmediately: Bool = false, action:@escaping ((ObservedValueType?, ObservedValueType?) -> Void)) -> U {
        let observation = self.createClosureObservation(requiresChange: requiresChange, action: action)
        if updateImmediately {
            observation.perform(oldValue: nil, newValue: self.value)
        }
        self.observations.add(observation, for: owner)
        return owner
    }
    
    private func createClosureObservation(requiresChange: Bool, action:@escaping ((ObservedValueType?, ObservedValueType?) -> Void)) -> ValueObservation<ObservedValueType> {
        let observation = ValueObservation<ObservedValueType>()
        observation.requiresChange = requiresChange
        observation.action = action
        return observation
    }
    
    public func notifyObservers(valueChanged: Bool = true) {
        self.observations.forEach { observation in
            if !observation.requiresChange || valueChanged {
                observation.perform(oldValue: nil, newValue: self.value)
            }
        }
    }
    
    /**
     Unregisters all observers and closures.
     */
    public func removeAllObservers() {
        self.observations.clear()
    }
    
    /**
     Unregisters an observer
     */
    public func removeObserver<U: AnyObject>(_ observer:U) {
        self.observations.remove(for: observer)
    }
    
    /**
     Removes an observation (an object returned from a closure observation)
     */
    public func removeObservation(_ observation:ValueObservation<ObservedValueType>) {
        self.observations.remove(observation)
    }

}

precedencegroup ObservationPrecedence {
    associativity: left
}

infix operator <--: ObservationPrecedence
infix operator -->: ObservationPrecedence
infix operator -/->: ObservationPrecedence
infix operator <-->: ObservationPrecedence

public func <--<T:ValueObservable, U:ValueObserver>(observer:U, observable:T) where U.ObservedValueType == T.ObservedValueType {
    observable --> observer
}

@discardableResult public func --><T:ValueObservable, U:ValueObserver>(observable:T, observer:U) -> U where U.ObservedValueType == T.ObservedValueType {
    return observable.addObserver(observer, updateImmediately: true)
}

@discardableResult public func --><T:ValueObservable>(observable:T, action:@escaping ((T.ObservedValueType?, T.ObservedValueType?) -> Void)) -> ValueObservation<T.ObservedValueType> {
    return observable.addObserver(updateImmediately: true, action: action)
}

public func -/-><T:ValueObservable, U:ValueObserver>(observable:T, observer:U) where U.ObservedValueType == T.ObservedValueType {
    observable.removeObserver(observer)
}

public func <--><T, U>(left: T, right: U) where T:ValueObserver, T:ValueObservable, U:ValueObserver, U:ValueObservable, T.ObservedValueType == U.ObservedValueType {
    // Order is important!
    left <-- right
    left --> right
}

