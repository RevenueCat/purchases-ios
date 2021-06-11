//
//  ETagAndResponseWrapper.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/11/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

let ETAG_KEY = "eTag"
let STATUS_CODE_KEY = "statusCode"
let RESPONSE_OBJECT_KEY = "responseObject"

internal struct ETagAndResponseWrapper {

    let eTag: String
    let statusCode: Int
    let responseObject: Dictionary<String, Any>

    func asDictionary() -> Dictionary<String, Any> {
        [
            ETAG_KEY: eTag,
            STATUS_CODE_KEY: statusCode,
            RESPONSE_OBJECT_KEY: responseObject
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
    init(with data: Data) throws {
        guard let dictionary =
                try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                    fatalError("Could not parse JSON Object from data!")
                }
        self.init(dictionary: dictionary)
    }

    init(dictionary: [String: Any]) {
        let eTag = dictionary[ETAG_KEY] as! String
        let statusCode = dictionary[STATUS_CODE_KEY] as! Int
        let responseObject = dictionary[RESPONSE_OBJECT_KEY] as! [String: Any]
        self.init(eTag: eTag, statusCode: statusCode, responseObject: responseObject)
    }
}
