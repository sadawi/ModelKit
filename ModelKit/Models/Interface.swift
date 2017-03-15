//
//  Interface.swift
//  ModelKit
//
//  Created by Sam Williams on 3/15/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

public class Interface {
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
            self.fieldsByKey[key] = newValue
        }
    }
    
    private func buildSortedFields() -> [FieldType] {
        let sorted = Array(self.fieldsByKey.values).sorted { $0.priority < $1.priority }
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
