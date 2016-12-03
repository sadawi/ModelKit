//
//  ModelStoreDelegate.swift
//  APIKit
//
//  Created by Sam Williams on 11/9/15.
//  Copyright © 2015 Sam Williams. All rights reserved.
//

import Foundation

public protocol ModelStoreDelegate {
    func modelStore(_ modelStore:ModelStore, didInstantiateModel model:Model)
    func modelStore(_ modelStore:ModelStore, canonicalObjectForIdentifier identifier:String, modelClass:AnyClass) -> Model?
}
