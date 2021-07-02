//
//  SubscriberAttribute.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/1/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCSubscriberAttribute) public class SubscriberAttribute: NSObject {

    @objc public static let keyKey = "key"
    @objc public static let valueKey = "value"
    @objc public static let setTimeKey = "setTime"
    @objc public static let isSyncedKey = "isSynced"

    static let backendValueKey = "value"
    static let backendTimestampKey = "updated_at_ms"

    public let setTime: Date

    @objc public let key: String
    @objc public let value: String
    @objc public var isSynced: Bool

    @objc required public init(withKey key: String, value: String?, isSynced: Bool, setTime: Date) {
        self.key = key
        self.value = value ?? ""
        self.isSynced = isSynced
        self.setTime = setTime
    }

    @objc convenience public init(withKey: String, value: String?) {
        self.init(withKey: withKey, value: value, dateProvider: DateProvider())
    }

    @objc convenience public init(withKey key: String, value: String?, dateProvider: DateProvider) {
        self.init(withKey: key, value: value, isSynced: false, setTime: dateProvider.now())
    }

    private override init() {
        fatalError("Init not supported from here")
    }

    @objc public func asDictionary() -> [String: NSObject] {
        return [Self.keyKey: self.key as NSString,
                Self.valueKey: self.value as NSString,
                Self.isSyncedKey: NSNumber(value: self.isSynced),
                Self.setTimeKey: self.setTime as NSDate]
    }

    @objc public func asBackendDictionary() -> [String: Any] {
        let timestamp = (self.setTime as NSDate).rc_millisecondsSince1970AsUInt64()

        return [Self.backendValueKey: self.value,
                Self.backendTimestampKey: timestamp]
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let attribute = object as? SubscriberAttribute else {
            return false
        }

        if self === attribute {
            return true
        } else if self.key != attribute.key {
            return false
        } else if self.value != attribute.value {
            return false
        } else if self.setTime != attribute.setTime {
            return false
        } else if self.isSynced != attribute.isSynced {
            return false
        }
        return true
    }

    public override var description: String {
        return "Subscriber attribute: key: \(self.key) value: \(self.value) setTime: \(self.setTime)"
    }
}
