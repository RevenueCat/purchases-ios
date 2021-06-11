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

internal class ETagAndResponseWrapper {

    let eTag: String
    let statusCode: Int
    let responseObject: Dictionary<String, Any>

    init(eTag: String, statusCode: Int, responseObject: Dictionary<String, Any>) {
        self.eTag = eTag
        self.statusCode = statusCode
        self.responseObject = responseObject
    }

    convenience init(with data: Data) throws {
        let dictionary =
                try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! Dictionary<String, Any>
        self.init(dictionary: dictionary)
    }

    convenience init(dictionary: Dictionary<String, Any>) {
        let eTag = dictionary[ETAG_KEY] as! String
        let statusCode = dictionary[STATUS_CODE_KEY] as! Int
        let responseObject = dictionary[RESPONSE_OBJECT_KEY] as! Dictionary<String, Any>
        self.init(eTag: eTag, statusCode: statusCode, responseObject: responseObject)
    }

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
