//
//  HTTPStatusCodes.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 4/19/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCHTTPStatusCodes) public enum HTTPStatusCodes: Int {
    case success = 200,
         redirect = 300,
         notModifiedResponseCode = 304,
         internalServerError = 500,
         notFoundError = 404,
         networkConnectTimeoutError = 599
}
