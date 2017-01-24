//  Created by Sam Williams on 6/5/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

private let kPropertyNameKey = "property"
private let kTargetKey = "target"
private let kChainSeparator = ": "

public struct FieldPath: ExpressibleByArrayLiteral, ExpressibleByStringLiteral, CustomStringConvertible {
    
    private(set) public var components: [String] = []
    var isPrefix: Bool = false
    
    public var length: Int {
        return self.components.count
    }
    
    static let wildcard = "*"
    
    public init(_ string: String, separator: String = ".") {
        self.init(string.components(separatedBy: separator))
    }
    
    public init(arrayLiteral elements: String...) {
        self.setComponents(elements)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(_ components: [String], isPrefix: Bool = false) {
        self.init()
        self.isPrefix = isPrefix
        self.setComponents(components)
    }
    
    public mutating func setComponents(_ components: [String]) {
        if components.last == FieldPath.wildcard {
            var components = components
            components.removeLast()
            self.isPrefix = true
            self.components = components
        } else {
            self.components = components
        }
    }
    
    /**
     - ["geometry"] is prefix of ["geometry", "size"], but not vice versa.
     - ["geometry"] is prefix of ["geometry"]
     - [] is prefix of all references
     */
    func isPrefix(of other: FieldPath) -> Bool {
        if other.components.count < self.components.count {
            return false
        }
        return Array(other.components[0..<self.components.count]) == self.components
    }
    
    func matches(_ other: FieldPath) -> Bool {
        if self.isPrefix {
            return self.isPrefix(of: other)
        } else {
            return self == other
        }
    }
    
    func prepending(propertyName: String) -> FieldPath {
        return FieldPath([propertyName] + self.components, isPrefix: self.isPrefix)
    }
    
    func appending(propertyName: String) -> FieldPath {
        return FieldPath(self.components + [propertyName], isPrefix: self.isPrefix)
    }

    func prepending(path: FieldPath) -> FieldPath {
        return FieldPath(path.components + self.components, isPrefix: self.isPrefix)
    }
    
    func appending(path: FieldPath) -> FieldPath {
        return FieldPath(self.components + path.components, isPrefix: self.isPrefix)
    }
    
    public var description: String {
        return self.components.joined(separator: "|")
    }
    
    public mutating func shift() -> String? {
        if self.components.count > 0 {
            return self.components.removeFirst()
        } else {
            return nil
        }
    }
}

public func ==(left: FieldPath, right: FieldPath) -> Bool {
    return left.components == right.components && left.isPrefix == right.isPrefix
}
