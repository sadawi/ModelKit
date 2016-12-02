//
//  Router.swift
//  ModelKit
//
//  Created by Sam Williams on 12/2/16.
//  Copyright © 2016 Sam Williams. All rights reserved.
//

import Foundation

open class Router {
    public static let defaultRouter = Router()
    
    func path(for: Model) -> String? {
        return nil
    }
    
    func path(for: Model.Type) -> String? {
        return nil
    }
}
