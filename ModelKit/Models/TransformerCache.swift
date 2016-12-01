//
//  TransformerCache.swift
//  APIKit
//
//  Created by Sam Williams on 5/5/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

private struct TransformerCache {
    static var transformers = TypeDictionary<ValueTransformerType>()
}

extension ValueTransformer {
    class var sharedInstance: ValueTransformer<T> {
        if let existing = TransformerCache.transformers[self] as? ValueTransformer<T> {
            return existing
        } else {
            let newInstance = self.init()
            TransformerCache.transformers[self] = newInstance
            return newInstance
        }
    }
}
