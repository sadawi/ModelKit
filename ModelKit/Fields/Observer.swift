//
//  Observer.swift
//  Pods
//
//  Created by Sam Williams on 1/5/16.
//
//

import Foundation

public protocol Observer:AnyObject {
    associatedtype ObservedValueType
    func valueChanged<ObservableType:Observable>(_ value:ObservedValueType?, observable:ObservableType?)
}
