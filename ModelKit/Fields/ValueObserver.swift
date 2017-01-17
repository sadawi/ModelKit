//
//  Observer.swift
//  Pods
//
//  Created by Sam Williams on 1/5/16.
//
//

import Foundation

public protocol ValueObserver:AnyObject {
    associatedtype ObservedValueType
    func observedValueChanged<ObservableType:ValueObservable>(from oldValue:ObservedValueType?, to newValue:ObservedValueType?, observable:ObservableType?)
}
