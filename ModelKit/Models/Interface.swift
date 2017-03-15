//
//  Interface.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

public class Interface {
    public static let defaultPriorityOffset = 1000
    
    /**
     The priority that will be assigned to new fields without their own priority. 
     This value will start at a large number (Interface.defaultPriorityOffset) and increase as they are added.
     */
    public var defaultPriority = Interface.defaultPriorityOffset
    
    public var fieldsByKey = [String: FieldType]() {
        didSet {
            self.sortedFields = nil
        }
    }
    private var sortedFields: [FieldType]? = nil
    
    public subscript(key: String) -> FieldType? {
        get {
            return self.fieldsByKey[key]
        }
        set {
            if newValue?.priority == nil {
                newValue?.priority = self.defaultPriority
                self.defaultPriority += 1
            }
            self.fieldsByKey[key] = newValue
        }
    }
    
    private func buildSortedFields() -> [FieldType] {
        let sorted = Array(self.fieldsByKey.values).sorted { ($0.priority ?? Int.max) < ($1.priority ?? Int.max) }
        self.sortedFields = sorted
        return sorted
    }
    
    public var fields: [FieldType] {
        if let sorted = self.sortedFields {
            return sorted
        } else {
            return self.buildSortedFields()
        }
    }
}
