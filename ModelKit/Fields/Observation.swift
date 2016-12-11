//
//  Observation.swift
//  Pods
//
//  Created by Sam Williams on 11/28/15.
//
//

import Foundation

/**
 An object that holds a closure that is to be run when a value changes.
 
 `Observation` instances are themselves `Observable`, which means they can be chained:
 ```
 let a = Field<String>()
 let b = Field<String>()
 let c = Field<String>()
 a --> b --> c
 ```
 */
open class Observation<T>: Observable {
    internal var uuid = UUID()
    
    public typealias ObservedValueType = T
    
    open var observations = ObservationRegistry<T>()
    
    open var value:T? {
        get {
            return self.getValue?()
        }
        set {
            self.onChange?(newValue)
            self.notifyObservers()
        }
    }
    
    var onChange:((T?) -> Void)?
    var getValue:((Void) -> T?)?
    
    open func valueChanged(_ newValue:T?) {
        self.value = newValue
    }
}

/**
 A mapping of owner objects to Observations.  Owner references are weak.  Observation references are strong.
 
 - Can add and remove anonymous observations
 - If an owner is dealloced, its observations will be nulled out.
 - TODO: Remove an owned observation without needing a reference to the owner.
 */
open class ObservationRegistry<V> {
    var ownedObservations:NSMapTable<AnyObject, Observation<V>> = NSMapTable.weakToStrongObjects()
    var unownedObservations = [UUID: Observation<V>]()
    
    public init() { }

    func clear() {
        self.unownedObservations.removeAll()
        self.ownedObservations.removeAllObjects()
    }
    
    func forEach(_ closure:((Observation<V>) -> Void)) {
        self.unownedObservations.values.forEach(closure)
        
        let enumerator = self.ownedObservations.objectEnumerator()
        while let observation = enumerator?.nextObject() {
            if let observation = observation as? Observation<V> {
                closure(observation)
            }
        }
    }
    
    func get<U:Observer>(for owner:U?) -> Observation<V>? where U.ObservedValueType==V {
        return self.ownedObservations.object(forKey: owner)
    }

    func add(_ observation:Observation<V>) {
        self.unownedObservations[observation.uuid] = observation
    }

    func add(_ observation:Observation<V>, for owner: AnyObject) {
        self.ownedObservations.setObject(observation, forKey: owner)
    }
    
    func remove<U:Observer>(for owner: U) where U.ObservedValueType==V {
        self.ownedObservations.removeObject(forKey: owner)
    }

    func remove<V>(_ observation: Observation<V>) {
        self.unownedObservations.removeValue(forKey: observation.uuid)
    }

}

