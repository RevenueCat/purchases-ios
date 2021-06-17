//
//  ETagAndResponseWrapper.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/11/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

internal struct ETagAndResponseWrapper {

    static let eTagKey = "eTag"
    static let statusCodeKey = "statusCode"
    static let responseObjectKey = "responseObject"

    let eTag: String
    let statusCode: Int
    let responseObject: [String: Any]

    func asDictionary() -> [String: Any] {
        [
            ETagAndResponseWrapper.eTagKey: eTag,
            ETagAndResponseWrapper.statusCodeKey: statusCode,
            ETagAndResponseWrapper.responseObjectKey: responseObject
        ]
    }

    func asData() -> Data? {
        let dictionary = asDictionary()
        if JSONSerialization.isValidJSONObject(dictionary) {
            do {
                return try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            } catch {
                return nil
            }
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
              let responseObject = dictionary[ETagAndResponseWrapper.responseObjectKey] as? [String: Any] else {
            Logger.error("Could not initialize ETagAndResponseWrapper Object from dictionary")
            return nil
        }
        self.init(eTag: eTag, statusCode: statusCode, responseObject: responseObject)
    }
}
