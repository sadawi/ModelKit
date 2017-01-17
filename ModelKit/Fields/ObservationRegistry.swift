//
//  ObservationRegistry.swift
//  ModelKit
//
//  Created by Sam Williams on 1/9/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

/**
 A mapping of owner objects to Observations.  Owner references are weak.  Observation references are strong.
 
 - Can add and remove anonymous observations
 - If an owner is dealloced, its observations will be nulled out.
 - TODO: Remove an owned observation without needing a reference to the owner.
 */
open class ObservationRegistry<ObservationType: Observation> {
    private var observations:NSMapTable<AnyObject, NSDictionary> = NSMapTable.weakToStrongObjects()
    
    public init() { }
    
    func clear() {
        self.observations.removeAllObjects()
    }
    
    func forEach(_ closure:((ObservationType) -> Void)) {
        let enumerator = self.observations.objectEnumerator()
        while let observations = enumerator?.nextObject() {
            if let observations = observations as? [UUID:ObservationType] {
                for (_, observation) in observations {
                    closure(observation)
                }
            }
        }
    }
    
    func get(for owner:AnyObject) -> [ObservationType] {
        if let observations = self.observations.object(forKey: owner) as? [UUID: ObservationType] {
            return Array(observations.values)
        } else {
            return []
        }
    }
    
    func add(_ observation:ObservationType) {
        self.add(observation, for: NSNull())
    }
    
    func add(_ observation:ObservationType, for owner: AnyObject) {
        var observations: [UUID: ObservationType]
        if let existing = self.observations.object(forKey: owner) as? [UUID: ObservationType] {
            observations = existing
        } else {
            observations = [:]
        }
        observations[observation.uuid] = observation
        self.observations.setObject(observations as NSDictionary, forKey: owner)
    }

    func remove(observation: ObservationType, for owner: AnyObject) {
        if let existing = self.observations.object(forKey: owner) as? [UUID: ObservationType] {
            var existing = existing
            existing.removeValue(forKey: observation.uuid)
            self.observations.setObject(existing as NSDictionary, forKey: owner)
        }
    }

    func remove(for owner: AnyObject) {
        self.observations.removeObject(forKey: owner)
    }
    
    func remove(_ observation: ObservationType) {
        self.remove(observation: observation, for: NSNull())
    }
    
}

