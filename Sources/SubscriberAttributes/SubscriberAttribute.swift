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

struct SubscriberAttribute {

    let setTime: Date
    let key: String
    let value: String
    var isSynced: Bool

    /// Whether the `setTime` should be ignored when generating the `individualizedCacheKeyPart`.
    ///
    /// If `true`, two attributes with the same `key` and `value` but different `setTime` will be treated as
    /// identical (e.g. to avoid duplicate Post Receipt requests when only `updated_at_ms` differs).
    let ignoreTimeInCacheIdentity: Bool

    init(
        withKey key: String,
        value: String?,
        isSynced: Bool,
        setTime: Date,
        ignoreTimeInCacheIdentity: Bool = false
    ) {
        self.key = key
        self.value = value ?? ""
        self.isSynced = isSynced
        self.setTime = setTime
        self.ignoreTimeInCacheIdentity = ignoreTimeInCacheIdentity
    }

    init(
        withKey key: String,
        value: String?,
        dateProvider: DateProvider = DateProvider(),
        ignoreTimeInCacheIdentity: Bool = false
    ) {
        self.init(
            withKey: key,
            value: value,
            isSynced: false,
            setTime: dateProvider.now(),
            ignoreTimeInCacheIdentity: ignoreTimeInCacheIdentity
        )
    }

    init(
        attribute: ReservedSubscriberAttribute,
        value: String?,
        dateProvider: DateProvider = DateProvider(),
        ignoreTimeInCacheIdentity: Bool = false
    ) {
        self.init(
            withKey: attribute.rawValue,
            value: value,
            dateProvider: dateProvider,
            ignoreTimeInCacheIdentity: ignoreTimeInCacheIdentity
        )
    }

}

extension SubscriberAttribute {

    init?(dictionary: [String: Any]) {
        guard let key = dictionary[Key.key.rawValue] as? String,
              let isSynced = (dictionary[Key.isSynced.rawValue] as? NSNumber)?.boolValue,
              let setTime = dictionary[Key.setTime.rawValue] as? Date else {
            return nil
        }

        let value = dictionary[Key.value.rawValue] as? String
        let ignoreTimeInCacheIdentity = (dictionary[Key.ignoreTimeInCacheIdentity.rawValue] as? NSNumber)?.boolValue
        ?? false

        self.init(
            withKey: key,
            value: value,
            isSynced: isSynced,
            setTime: setTime,
            ignoreTimeInCacheIdentity: ignoreTimeInCacheIdentity
        )
    }

    func asDictionary() -> [String: NSObject] {
        return [Key.key.rawValue: self.key as NSString,
                Key.value.rawValue: self.value as NSString,
                Key.isSynced.rawValue: NSNumber(value: self.isSynced),
                Key.setTime.rawValue: self.setTime as NSDate,
                Key.ignoreTimeInCacheIdentity.rawValue: NSNumber(value: self.ignoreTimeInCacheIdentity)]
    }

    func asBackendDictionary() -> [String: Any] {
        return [BackendKey.value.rawValue: self.value,
                BackendKey.timestamp.rawValue: self.setTime.millisecondsSince1970]
    }

    var individualizedCacheKeyPart: String {
        return "[SubscriberAttribute] key: \(self.key) value: \(self.value)" +
        (ignoreTimeInCacheIdentity ? "" : " setTime: \(self.setTime)")
    }

}

extension SubscriberAttribute: Equatable {}

extension SubscriberAttribute: CustomStringConvertible {

    var description: String {
        return "[SubscriberAttribute] key: \(self.key) value: \(self.value) setTime: \(self.setTime)"
    }

}

extension SubscriberAttribute {

    typealias Dictionary = [String: SubscriberAttribute]

}

extension SubscriberAttribute {

    static func map(subscriberAttributes: SubscriberAttribute.Dictionary) -> [String: [String: Any]] {
        return subscriberAttributes.mapValues { $0.asBackendDictionary() }
    }
}

extension SubscriberAttribute.Dictionary {

    var individualizedCacheKeyPart: String {
        return self.mapValues {
            $0.individualizedCacheKeyPart
        }.debugDescription
    }
}

// MARK: - Private

extension SubscriberAttribute {

    private enum Key: String {

        case key
        case value
        case isSynced
        case setTime
        case ignoreTimeInCacheIdentity

    }

    private enum BackendKey: String {

        case value = "value"
        case timestamp = "updated_at_ms"

    }

}
