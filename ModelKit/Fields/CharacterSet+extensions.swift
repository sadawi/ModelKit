//
//  CharacterSet+extensions.swift
//  ModelKit
//
//  Created by Sam Williams on 2/7/17.
//  Copyright © 2017 Sam Williams. All rights reserved.
//

import Foundation

public extension CharacterSet {
    static var uppercaseHexadecimal = CharacterSet(charactersIn: "ABCDEF0123456789")
    static var lowercaseHexadecimal = CharacterSet(charactersIn: "abcdef0123456789")
}
