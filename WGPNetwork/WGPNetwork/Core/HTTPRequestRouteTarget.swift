//
//  HTTPRequestRouteTarget.swift
//  T3Demo
//
//  Created by jiahongyuan on 2018/9/20.
//  Copyright © 2018年 jiahongyuan. All rights reserved.
//

import Foundation
import Moya

struct HTTPRequestRouteTarget: TargetType {
    
    private let _host: String
    
    private let _path: String
    
    private let _method: Moya.Method
    
    private let _parameters: [String: Any]
    
    private let _contentType: HeaderContentType
    
    private let _multipartDatas: [MultipartFormData]?
    
    private let _headers: [String: String]?
    
    init(host: String, path: String, method: Moya.Method, parameters: [String: Any], contentType: HeaderContentType, multipartDatas: [MultipartFormData]? = nil, headers: [String: String]? = nil) {
        _host = host
        _path = path
        _method = method
        _parameters = parameters
        _contentType = contentType
        _multipartDatas = multipartDatas
        _headers = headers
    }
    
    var baseURL: URL {
        guard let url = URL(string: _host) else {
            fatalError("RouteService 创建 baseURL失败，请检查 host 是否设置正确")
        }
        return url
    }
    
    var path: String {
        return _path
    }
    var method: Moya.Method {
        return _method
    }
    
    var sampleData: Data {
        do {
            return try JSONSerialization.data(withJSONObject: _parameters, options: .prettyPrinted)
        } catch {
            network_log("请求参数存根失败")
            return Data()
        }
    }
    
    var task: Task {
        switch _contentType  {
        case .urlEncoding:
            return .requestParameters(parameters: _parameters, encoding: URLEncoding.methodDependent)
        case .json:
            return .requestParameters(parameters: _parameters, encoding: JSONEncoding.default)
        case .multipart:
            guard let multipartDatas = _multipartDatas else {
                fatalError("multipartDatas 不能为空")
            }
            return .uploadCompositeMultipart(multipartDatas, urlParameters: _parameters)
        }
    }
    
    var headers: [String: String]? {
        var headers: [String: String] = [:]
        if let sourceHeaders = _headers {
            headers = sourceHeaders
        }
        switch _contentType {
        case .json:
            headers["Content-Type"] = "application/json"
        case .urlEncoding:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        case .multipart:
            headers["Content-Type"] = "multipart/form-data"
        }
        return headers
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
