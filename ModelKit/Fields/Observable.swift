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
public protocol Observable: class {
    associatedtype ObservedValueType
    var value: ObservedValueType? { get set }
    var observations: ObservationRegistry<ObservedValueType> { get }
}

public extension Observable {
    /**
     Registers a value change observer.
     
     - parameter observer: an Observer object that will receive change notifications
     */
    @discardableResult public func addObserver<U:Observer>(_ observer:U) -> U where U.ObservedValueType==ObservedValueType {
        let observation = Observation<ObservedValueType>()
        observation.onChange = { (value:ObservedValueType?) -> Void in
            observer.valueChanged(value, observable:self)
        }
        observation.valueChanged(self.value)
        observation.getValue = { [weak self] in
            return self?.value
        }
        self.observations.set(observer, observation)
        return observer
    }
    
    /**
     Registers a value change action.
     
     - parameter onChange: A closure to be run when the value changes
     */
    public func addObserver(onChange:@escaping ((ObservedValueType?) -> Void)) -> Observation<ObservedValueType> {
        let observation = self.createClosureObservation(onChange: onChange)
        self.observations.setNil(observation)
        return observation
    }

    /**
     Registers a value change action, along with a generic owner.
     
     - parameter owner: The observation owner, used only as a key for registering the action
     - parameter onChange: A closure to be run when the value changes
     */
    @discardableResult public func addObserver<U: AnyObject>(_ owner:U, onChange:@escaping ((ObservedValueType?) -> Void)) -> U {
        let observation = self.createClosureObservation(onChange: onChange)
        self.observations.set(owner, observation)
        return owner
    }
    
    private func createClosureObservation(onChange:@escaping ((ObservedValueType?) -> Void)) -> Observation<ObservedValueType> {
        let observation = Observation<ObservedValueType>()
        observation.onChange = onChange
        observation.valueChanged(self.value)
        observation.getValue = { [weak self] in
            return self?.value
        }
        return observation
    }
    
    public func notifyObservers() {
        self.observations.each { observation in
            observation.valueChanged(self.value)
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
    public func removeObserver<U:Observer>(_ observer:U) where U.ObservedValueType==ObservedValueType {
        self.observations.remove(observer)
    }
}

precedencegroup ObservationPrecedence {
    associativity: left
}

infix operator <--: ObservationPrecedence
infix operator -->: ObservationPrecedence
infix operator -/->: ObservationPrecedence
infix operator <-->: ObservationPrecedence

public func <--<T:Observable, U:Observer>(observer:U, observedField:T) where U.ObservedValueType == T.ObservedValueType {
    observedField.addObserver(observer)
}

@discardableResult public func --><T:Observable, U:Observer>(observable:T, observer:U) -> U where U.ObservedValueType == T.ObservedValueType {
    return observable.addObserver(observer)
}

@discardableResult public func --><T:Observable>(observable:T, onChange:@escaping ((T.ObservedValueType?) -> Void)) -> Observation<T.ObservedValueType> {
    return observable.addObserver(onChange: onChange)
}

public func -/-><T:Observable, U:Observer>(observable:T, observer:U) where U.ObservedValueType == T.ObservedValueType {
    observable.removeObserver(observer)
}

public func <--><T, U>(left: T, right: U) where T:Observer, T:Observable, U:Observer, U:Observable, T.ObservedValueType == U.ObservedValueType {
    // Order is important!
    right.addObserver(left)
    left.addObserver(right)
}

