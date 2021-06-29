//
//  Dictionary+Extensions.swift
//  PurchasesCoreSwift
//
//  Created by Josh Holtz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

public extension NSDictionary {
    @objc func rc_removingNSNullValues() -> NSDictionary {
        let result = NSMutableDictionary()
        for (key, value) in self where !(value is NSNull) {
            result[key] = value
        }
        return result
    }
}
