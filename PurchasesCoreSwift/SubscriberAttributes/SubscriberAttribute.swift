//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttribute.swift
//
//  Created by Joshua Liebowitz on 7/1/21.
//

import Foundation

class SubscriberAttribute {

    static private let backendValueKey = "value"
    static private let backendTimestampKey = "updated_at_ms"

    static let keyKey = "key"
    static let valueKey = "value"
    static let setTimeKey = "setTime"
    static let isSyncedKey = "isSynced"

    let setTime: Date
    let key: String
    let value: String
    var isSynced: Bool

    required init(withKey key: String, value: String?, isSynced: Bool, setTime: Date) {
        self.key = key
        self.value = value ?? ""
        self.isSynced = isSynced
        self.setTime = setTime
    }

    convenience init(withKey: String, value: String?) {
        self.init(withKey: withKey, value: value, dateProvider: DateProvider())
    }

    convenience init(withKey key: String, value: String?, dateProvider: DateProvider) {
        self.init(withKey: key, value: value, isSynced: false, setTime: dateProvider.now())
    }

    func asDictionary() -> [String: NSObject] {
        return [Self.keyKey: self.key as NSString,
                Self.valueKey: self.value as NSString,
                Self.isSyncedKey: NSNumber(value: self.isSynced),
                Self.setTimeKey: self.setTime as NSDate]
    }

    func asBackendDictionary() -> [String: Any] {
        let timestamp = self.setTime.millisecondsSince1970AsUInt64()

        return [Self.backendValueKey: self.value,
                Self.backendTimestampKey: timestamp]
    }

}

extension SubscriberAttribute: Equatable {

    static func == (lhs: SubscriberAttribute, rhs: SubscriberAttribute) -> Bool {
        if lhs === rhs {
            return true
        } else if lhs.key != rhs.key {
            return false
        } else if lhs.value != rhs.value {
            return false
        } else if lhs.setTime != rhs.setTime {
            return false
        } else if lhs.isSynced != rhs.isSynced {
            return false
        }
        return true
    }

}

extension SubscriberAttribute: CustomStringConvertible {

    var description: String {
        return "Subscriber attribute: key: \(self.key) value: \(self.value) setTime: \(self.setTime)"
    }

}
