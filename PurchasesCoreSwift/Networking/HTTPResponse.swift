//
//  HTTPResponse.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 4/19/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCHTTPResponse) public class HTTPResponse: NSObject {

    @objc public let statusCode: Int
    @objc public let jsonObject: [String: Any]?

    @objc public init(statusCode: Int, jsonObject: [String: Any]?) {
        self.statusCode = statusCode
        self.jsonObject = jsonObject
    }
}
