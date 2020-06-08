//
//  HTTPRequestProtocol.swift
//  T3Demo
//
//  Created by jiahongyuan on 2018/9/20.
//  Copyright © 2018年 jiahongyuan. All rights reserved.
//

import Foundation
import Moya

/// HTTP headers 中的 Content-Type 类型
public enum HeaderContentType: String, RawRepresentable {
    case json = "application/json;charset=utf-8"
    case urlEncoding = "application/x-www-form-urlencoded"
    case multipart = "multipart/form-data"
}

public protocol HTTPRequestProtocol {
    /// response 对应的解析 model
    associatedtype Model: HTTPResponseModeling
    
    typealias SuccessHandler = (Model) -> Void
    typealias ErrorHandler = (Error) -> Void
    
    /// 自定义请求头， 不包含 Content-Type 字段
    var headers: [String: String]? { get }
    /// 请求头 Content-Type 类型
    var contentType: HeaderContentType { get }
    /// 主机地址
    var host: String { get }
    /// 请求方法
    var method: Moya.Method { get }
    /// 请求参数
    var parameters: [String: Any]? { get }
    /// 每个请求默认携带的参数
    var defaultParams: [String: Any] { get }
    /// 请求路径
    var path: String { get }
    /// 是否使用 HTTPS
    var useHTTPS: Bool { get }
    /// 是否要求登录
    var requiredLogin: Bool { get }
    /// 客户端的p12路径
    var clientPKCS12Path: String? { get }
    /// 表单上传数据
    var multipartDatas: [Moya.MultipartFormData]? { get }
    /// 请求回调执行的队列
    var callbackQueue: DispatchQueue { get }
    /// 进度回调
    var progressBlock: Moya.ProgressBlock? { get }
    /// 发送请求
    ///
    /// - Parameters:
    ///   - successHandler: 成功回调
    ///   - errorHandler: 错误回调
    /// - Returns: 取消句柄
    func sendRequest(_ successHandler: SuccessHandler?, errorHandler: ErrorHandler?) -> Cancellable?
    /// 错误回调前错误处理，可以在此统一处理一些错误
    func preprocessError(_ error: Error)
}




