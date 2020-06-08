//
//  HTTPResponseModeling.swift
//  T3Demo
//
//  Created by jiahongyuan on 2018/9/20.
//  Copyright © 2018年 jiahongyuan. All rights reserved.
//

import Foundation
import HandyJSON

public protocol HTTPResponseModeling: HandyJSON {
    var originalRequest: URLRequest? { set get }
}

public struct EmptyModel: HTTPResponseModeling {
    public init() {}
    public var originalRequest: URLRequest?
}
