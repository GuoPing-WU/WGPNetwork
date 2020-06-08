//
//  HTTPServiceLog.swift
//  T3Demo
//
//  Created by jiahongyuan on 2018/9/20.
//  Copyright © 2018年 jiahongyuan. All rights reserved.
//

import Foundation

#if DEBUG
func network_log(_ items: Any..., separator: String = " , ", terminator: String = "") {
    let itemsString = items.map({"\($0)"}).joined(separator: separator).appending(terminator)
    print(itemsString)
}
#else
func network_log(_ items: Any..., separator: String = " , ", terminator: String = "") {}
#endif
