//
//  ETagAndResponseWrapper.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/11/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

struct ETagAndResponseWrapper {

    private static let eTagKey = "eTag"
    private static let statusCodeKey = "statusCode"
    private static let jsonObjectKey = "responseObject"

    let eTag: String
    let statusCode: Int
    let jsonObject: [String: Any]

    func asDictionary() -> [String: Any] {
        [
            ETagAndResponseWrapper.eTagKey: eTag,
            ETagAndResponseWrapper.statusCodeKey: statusCode,
            ETagAndResponseWrapper.jsonObjectKey: jsonObject
        ]
    }

    func asData() -> Data? {
        let dictionary = asDictionary()
        if JSONSerialization.isValidJSONObject(dictionary) {
            return try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        }
        return nil
    }
}

extension ETagAndResponseWrapper {
    init?(with data: Data) {
        guard let dictionary =
                try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                    Logger.error("Could not initialize ETagAndResponseWrapper Object from data")
                    return nil
                }
        self.init(dictionary: dictionary)
    }

    init?(dictionary: [String: Any]) {
        guard let eTag = dictionary[ETagAndResponseWrapper.eTagKey] as? String,
              let statusCode = dictionary[ETagAndResponseWrapper.statusCodeKey] as? Int,
              let jsonObject = dictionary[ETagAndResponseWrapper.jsonObjectKey] as? [String: Any] else {
            Logger.error("Could not initialize ETagAndResponseWrapper Object from dictionary")
            return nil
        }
        self.init(eTag: eTag, statusCode: statusCode, jsonObject: jsonObject)
    }
}
