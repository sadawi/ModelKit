//
//  ValueObservation.swift
//  ModelKit
//
//  Created by Sam Williams on 1/9/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
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
open class ValueObservation<T>: Observation {
    public typealias Action = ((T?) -> Void)
    public var uuid = UUID()
    
    public typealias ObservedValueType = T
    
    public var onChange:Action?
    
    open func valueChanged(_ newValue:T?) {
        self.onChange?(newValue)
    }
}

/**
 A mapping of owner objects to Observations.  Owner references are weak.  Observation references are strong.
 
 - Can add and remove anonymous observations
 - If an owner is dealloced, its observations will be nulled out.
 - TODO: Remove an owned observation without needing a reference to the owner.
 */
open class ObservationRegistry<ObservationType: Observation> {
    var ownedObservations:NSMapTable<AnyObject, ObservationType> = NSMapTable.weakToStrongObjects()
    var unownedObservations = [UUID: ObservationType]()
    
    public init() { }
    
    func clear() {
        self.unownedObservations.removeAll()
        self.ownedObservations.removeAllObjects()
    }
    
    func forEach(_ closure:((ObservationType) -> Void)) {
        self.unownedObservations.values.forEach(closure)
        
        let enumerator = self.ownedObservations.objectEnumerator()
        while let observation = enumerator?.nextObject() {
            if let observation = observation as? ObservationType {
                closure(observation)
            }
        }
    }
    
    func get(for owner:AnyObject) -> ObservationType? {
        return self.ownedObservations.object(forKey: owner)
    }
    
    func add(_ observation:ObservationType) {
        self.unownedObservations[observation.uuid] = observation
    }
    
    func add(_ observation:ObservationType, for owner: AnyObject) {
        self.ownedObservations.setObject(observation, forKey: owner)
    }
    
    func remove(for owner: AnyObject) {
        self.ownedObservations.removeObject(forKey: owner)
    }
    
    func remove(_ observation: ObservationType) {
        self.unownedObservations.removeValue(forKey: observation.uuid)
    }
    
}

