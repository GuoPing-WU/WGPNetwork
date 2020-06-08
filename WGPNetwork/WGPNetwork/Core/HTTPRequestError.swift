//
//  NetworkError.swift
//  T3Demo
//
//  Created by jiahongyuan on 2018/9/20.
//  Copyright © 2018年 jiahongyuan. All rights reserved.
//

import Foundation
import Moya

public struct NetServiceError: LocalizedError {
    public var code: Int
    public var message: String
    public var errorDescription: String? {
        return message
    }
}
