//
//  Observable.swift
//  ModelKit
//
//  Created by Sam Williams on 1/10/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

public protocol Observable: class {
    /// A minimal observation
    func addObserver(updateImmediately: Bool, action:@escaping ((Void) -> Void))
}

public extension Observable {
    func addObserver(action:@escaping ((Void) -> Void)) {
        self.addObserver(updateImmediately: false, action: action)
    }
}
