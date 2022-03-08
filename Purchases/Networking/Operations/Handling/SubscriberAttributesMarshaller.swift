//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributesMarshaller.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

enum SubscriberAttributesMarshaller {

    // fixme: make `SubscriberAttributeDict` `Encodable` instead
    static func map(subscriberAttributes: SubscriberAttributeDict) -> [String: [String: Any]] {
        var attributesByKey: [String: [String: Any]] = [:]
        for (key, value) in subscriberAttributes {
            attributesByKey[key] = value.asBackendDictionary()
        }
        return attributesByKey
    }

}
