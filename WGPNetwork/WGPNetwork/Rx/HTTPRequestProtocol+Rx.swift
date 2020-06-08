//
//  HTTPRequestProtocol+Rx.swift
//  T3Go
//
//  Created by jiahongyuan on 2018/9/22.
//  Copyright © 2018年 CCC. All rights reserved.
//

import Foundation
import RxSwift

extension Reactive where Base: HTTPRequestProtocol {
    public func sendRequest() -> Single<Base.Model> {
        return Single<Base.Model>.create(subscribe: { (single) -> Disposable in
            let cancel = self.base.sendRequest({ (model) in
                single(.success(model))
            }, errorHandler: { (error) in
                single(.error(error))
            })
            return Disposables.create {
                cancel?.cancel()
            }
        })
    }
}
