//
//  SubscriberAttribute.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/1/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCSubscriberAttribute) public class SubscriberAttribute: NSObject {
    static private let backendValueKey = "value"
    static private let backendTimestampKey = "updated_at_ms"

    // TODO (Post-migration): remove public.
    static let keyKey = "key"
    static let valueKey = "value"
    static let setTimeKey = "setTime"
    static let isSyncedKey = "isSynced"
    let setTime: Date

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

    convenience init(withKey key: String, value: String?, dateProvider: DateProvider) {
        self.init(withKey: key, value: value, isSynced: false, setTime: dateProvider.now())
    }

    private override init() {
        fatalError("Init not supported from here")
    }

    func asDictionary() -> [String: NSObject] {
        return [Self.keyKey: self.key as NSString,
                Self.valueKey: self.value as NSString,
                Self.isSyncedKey: NSNumber(value: self.isSynced),
                Self.setTimeKey: self.setTime as NSDate]
    }

    func asBackendDictionary() -> [String: Any] {
        let timestamp = self.setTime.rc_millisecondsSince1970AsUInt64()

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
