//
//  HTTPRequestProtocol+Default.swift
//  T3Go
//
//  Created by jiahongyuan on 2018/9/22.
//  Copyright © 2018年 CCC. All rights reserved.
//

import Foundation
import Moya
import CryptoSwift
import HandyJSON
import SwiftyJSON
import Alamofire

public extension HTTPRequestProtocol {
    var headers: [String: String]? {
        return nil
    }
    
    var contentType: HeaderContentType {
        return .json
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var useHTTPS: Bool {
        return false
    }
    
    var serverCertificatePath: String? {
        return Bundle.main.path(forResource: "server", ofType: "cer")
    }
    
    var clientPKCS12Path: String? {
        return Bundle.main.path(forResource: "client", ofType: "p12")
    }
    
    var multipartDatas: [Moya.MultipartFormData]? {
        return nil
    }
    
    var callbackQueue: DispatchQueue {
        return DispatchQueue.main
    }
    
    var progressBlock: Moya.ProgressBlock? {
        return nil
    }
}

extension HTTPRequestProtocol {

    func asRouteTarget() -> HTTPRequestRouteTarget {
        var requestParams: [String: Any] = parameters ?? [:]
        var headers: [String: String] = self.headers ?? [:]
        headers["Content-Type"] = "application/json"
        switch contentType {
        case .json:
            var defaultHeaders = defaultParams
            defaultHeaders["noncestr"] = "\(defaultParams["noncestr"] ?? Date().timeIntervalSince1970)"
            headers.merge(defaultHeaders as! [String: String], uniquingKeysWith: {(key1, key2) in return key1})
            headers["sign"] = sign(requestParams)
        case .urlEncoding, .multipart:
            requestParams = requestParameters(parameters, defaultParams: defaultParams)
            requestParams["sign"] = sign(requestParams)
        }
        if self.path != "/api/v1/vehicle/token/nearby" {
            print(">>>>>>>>>>>>\n\(path)")
            print(headers)
            print(requestParams)
        }
        return HTTPRequestRouteTarget(host: host, path: path, method: method, parameters: requestParams, contentType: contentType, multipartDatas: multipartDatas, headers: headers)
    }
    
    @discardableResult
    public func sendRequest(_ successHandler: SuccessHandler?, errorHandler: ErrorHandler?) -> Cancellable? {
        
        let manager = MoyaProvider<HTTPRequestRouteTarget>.defaultAlamofireManager()
        if useHTTPS {
            configureAuthenticationChallenge(manager)
        }
        let provider = MoyaProvider<HTTPRequestRouteTarget>(manager: manager)
        
        #if !DEBUG
        guard isNoProxy() else { return nil }
        #endif
        
        return provider.request(self.asRouteTarget(), callbackQueue: self.callbackQueue, progress: self.progressBlock) { (result) in
            switch result {
            case .success(let response):
                let json = JSON(response.data)
//                let success = json["success"].boolValue
                let success = json["code"].intValue == 200
                print("<<<<<<<<<<< \n\(self.path)")
                print(response)
                print(result)
                print(success)
                print(json)
//                if self.path != "/api/v1/vehicle/token/nearby" {
//
//                }
                guard success else {
                    let errorCode = json["code"].intValue
                    let error = NetServiceError(code: errorCode, message: json["msg"].stringValue)
                    self.preprocessError(error)
                    errorHandler?(error)
                    print("<<<<<<<<<<< \n\(self.path)")
                    print(error)
                    return
                }
                var responseModel = Model()
                if json["data"] != JSON.null {
                    guard let jsonString = response.data.utf8Representation, let model = Model.deserialize(from: jsonString, designatedPath: "data") else {
                        errorHandler?(NetServiceError(code: -101, message: "从 response.data 映射 Model 失败"))
                        return
                    }
                    responseModel = model
                }
                
                #if DEBUG
                // 调试模式附加 请求信息
                responseModel.originalRequest = response.request
                #endif
                successHandler?(responseModel)
            case .failure(let error):
                print("<<<<<<<<<<< \n\(self.path)")
                print(error)
                errorHandler?(error)
            }
        }
    }
    
    @discardableResult
    public func sendCustomRequest(_ successHandler: @escaping (String) -> (), errorHandler: ErrorHandler?) -> Cancellable {
        let manager = MoyaProvider<HTTPRequestRouteTarget>.defaultAlamofireManager()
        if useHTTPS {
            configureAuthenticationChallenge(manager)
        }
        let provider = MoyaProvider<HTTPRequestRouteTarget>(manager: manager)
        return provider.request(self.asRouteTarget(), callbackQueue: self.callbackQueue, progress: self.progressBlock) { (result) in
            switch result {
            case .success(let response):
//                let json = JSON(response.data)
//                let success = json["success"].boolValue
//                guard success else {
//                    let errorCode = json["errCode"].intValue
//                    let error = NetServiceError(code: errorCode, message: json["msg"].stringValue)
//                    self.preprocessError(error)
//                    errorHandler?(error)
//                    return
//                }
                successHandler(String.init(data: response.data, encoding: .utf8) ?? "")
                
            case .failure(let error):
                errorHandler?(error)
            }
        }
    }
}

extension HTTPRequestProtocol {
    private func isNoProxy() -> Bool {
        let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
        let proxies = CFNetworkCopyProxiesForURL(URL(string: host ?? "") as! CFURL, proxySettings!).takeRetainedValue()
        let settings = unsafeBitCast(CFArrayGetValueAtIndex(proxies, 0), to: NSDictionary.self)
        let proxyType: CFString = settings.object(forKey: kCFProxyTypeKey) as! CFString
        return proxyType == kCFProxyTypeNone
    }
}

extension HTTPRequestProtocol {
    
    /// 参数指纹
    ///
    /// - Parameter parameters: 需要生成指纹的参数
    /// - Returns: 生成的指纹
    func sign(_ parameters: [String: Any]) -> String {
        guard parameters.count != 0 else {
            return "1111"
        }
        let allKeys = parameters.keys.sorted { $0 < $1 }
        let nonEmptyKeys = allKeys.filter{ !$0.isEmpty }
        let keyValuePairs = nonEmptyKeys.map({"\($0)=\(String(describing: parameters[$0]))"})
        var kvPairsString = keyValuePairs.joined(separator: "&")
        if kvPairsString.range(of: " ") != nil {
            kvPairsString = kvPairsString.replacingOccurrences(of: " ", with: "")
        }
        return kvPairsString.md5()
    }
    /// 配置 认证挑战
    ///
    /// - Parameter manager: 需要配置的 Manager
    fileprivate func configureAuthenticationChallenge(_ manager: Moya.Manager) {
        manager.delegate.sessionDidReceiveChallengeWithCompletion = { (session, challenge, completion) in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            switch challenge.protectionSpace.authenticationMethod {
            case NSURLAuthenticationMethodServerTrust:
                let host = challenge.protectionSpace.host
                let serverTrustPolicy  = ServerTrustPolicy.pinCertificates(certificates: ServerTrustPolicy.certificates(), validateCertificateChain: true, validateHost: true)
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    if serverTrustPolicy.evaluate(serverTrust, forHost: host) {
                        disposition = .useCredential
                        credential = URLCredential(trust: serverTrust)
                    } else {
                        disposition = .cancelAuthenticationChallenge
                    }
                }
            case NSURLAuthenticationMethodClientCertificate:
                if let trust = self.clientTrust(from: self.clientPKCS12Path ?? "") {
                    disposition = .useCredential
                    credential = URLCredential(trust: trust)
                }
            default:
                break
            }
            completion(disposition, credential)
        }
    }
    
    /// 生成客户端 SecTrust
    ///
    /// - Parameter path: 客户端 p12 路径
    /// - Returns: 客户端 SecTrust
    fileprivate func clientTrust(from pkcs12Path: String) -> SecTrust? {
        guard let pkcs12FileURL = URL(string: pkcs12Path) else {
            network_log("HTTPS 双向认证需要设置 p12 文件路径")
            return nil
        }
        guard let pkcs12Data = try? Data(contentsOf: pkcs12FileURL) else {
            network_log("从指定的路径加载  p12 失败: \(pkcs12Path)")
            return nil
        }
        var items: CFArray?
        let status = SecPKCS12Import(pkcs12Data as CFData, [kSecImportExportPassphrase: ",./123qwe"] as CFDictionary, &items)
        if status != errSecSuccess {
            network_log("pkcs12 导入失败，错误码: \(status), 请在文档 Security Framework Result Codes 查看错误原因")
        }
        guard let pkcs12Items = (items as [AnyObject]?) else {
            network_log("无法获取到 pkcs12 内容信息")
            return nil
        }
        let pkcs12Info = pkcs12Items[0] as? [CFString: AnyObject]
        
        guard let trustObject = pkcs12Info?[kSecImportItemTrust] else {
            return nil
        }
        let trust = trustObject as! SecTrust
        return trust
    }
    
    /// 合并 API 特定参数 和 全局默认参数，并添加指纹信息
    ///
    /// - Parameters:
    ///   - parameters: API特定参数
    ///   - defaultParams: 全局默认参数
    /// - Returns: 合并并且添加指纹后的参数
    fileprivate func requestParameters(_ parameters: [String: Any]?, defaultParams: [String: Any]) -> [String: Any] {
        var params = defaultParams
        if let parameters = parameters {
            params.merge(parameters) { (key1, key2) -> Any in
                return key1
            }
        }
        return params
    }
}

public extension Data {
    var utf8Representation: String? {
        return String(data: self, encoding: .utf8)
    }
}
