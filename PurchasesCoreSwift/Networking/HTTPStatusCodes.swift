//
//  HTTPStatusCodes.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/1/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(Post-migration): switch this back to internal
@objc(RCHTTPStatusCodes) public enum HTTPStatusCodes: UInt {
    case redirect = 300
    case internalServerError = 500
    case notFound = 404
    case networkConnectTimeoutError = 599
}
