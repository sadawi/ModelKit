//
//  HasOwnerModel.swift
//  ModelKit
//
//  Created by Sam Williams on 12/2/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol HasOwnerField {
    /**
     The field on this object that points to this object's owner.
     */
    var ownerField: ModelFieldType? { get }
}
