//  Created by Sam Williams on 6/5/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

private let kPropertyNameKey = "property"
private let kTargetKey = "target"
private let kChainSeparator = ": "

public class FieldPath: ExpressibleByArrayLiteral, Hashable, CustomStringConvertible {
    private(set) public var propertyChain: [String] = []
    var isPrefix: Bool = false
    
    public static var any: FieldPath {
        return FieldPath(propertyChain: [], isPrefix: true)
    }
    
    static let wildcard = "*"
    
    public required init(arrayLiteral elements: String...) {
        self.setPropertyChain(elements)
    }
    
    public convenience init(propertyChain: [String], isPrefix: Bool = false) {
        self.init()
        self.isPrefix = isPrefix
        self.setPropertyChain(propertyChain)
    }
    
    public func setPropertyChain(_ propertyChain: [String]) {
        if propertyChain.last == FieldPath.wildcard {
            var propertyChain = propertyChain
            propertyChain.removeLast()
            self.isPrefix = true
            self.propertyChain = propertyChain
        } else {
            self.propertyChain = propertyChain
        }
    }
    
    /**
     Is this a non-strict superset of (i.e., less specific than or equal to) the other reference?
     Example:
     - ["geometry"] is prefix of ["geometry", "size"], but not vice versa.
     - ["geometry"] is prefix of ["geometry"]
     - [] is prefix of all references
     */
    func isPrefix(of other: FieldPath) -> Bool {
        if other.propertyChain.count < self.propertyChain.count {
            return false
        }
        return Array(other.propertyChain[0..<self.propertyChain.count]) == self.propertyChain
    }
    
    func matches(other: FieldPath) -> Bool {
        if self.isPrefix {
            return self.isPrefix(of: other)
        } else {
            return self == other
        }
    }
    
    fileprivate var stringValue: String {
        var result = self.propertyChain.joined(separator: "---")
        if self.isPrefix {
            result.append("*")
        }
        return result
    }
    
    public var hashValue: Int {
        return self.stringValue.hash
    }
    
    func prepending(propertyName: String) -> FieldPath {
        return FieldPath(propertyChain: [propertyName] + self.propertyChain, isPrefix: self.isPrefix)
    }
    
    func appending(propertyName: String) -> FieldPath {
        return FieldPath(propertyChain: self.propertyChain + [propertyName], isPrefix: self.isPrefix)
    }
    
    public var description: String {
        return self.propertyChain.joined(separator: "|")
    }
}

public func ==(left: FieldPath, right: FieldPath) -> Bool {
    // TODO: technically, we're ignoring prototypes here.
    return left.stringValue == right.stringValue
}
