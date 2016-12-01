//
//  ValueTransformerContext.swift
//  ModelKit
//
//  Created by Sam Williams on 12/1/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

public protocol ValueTransformerContext {
    func transformer<T:Equatable>(for field: Field<T>) -> ValueTransformer<T>?
}

public class DefaultValueTransformerContext: ValueTransformerContext {
    public func transformer<T:Equatable>(for field: Field<T>) -> ValueTransformer<T>? {
        return SimpleValueTransformer<T>()
    }
}
