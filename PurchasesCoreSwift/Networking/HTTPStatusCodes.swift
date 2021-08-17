//
//  HTTPStatusCodes.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 4/19/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

enum HTTPStatusCodes: Int {
    case success = 200,
         createdSuccess = 201,
         redirect = 300,
         notModifiedResponseCode = 304,
         internalServerError = 500,
         notFoundError = 404,
         networkConnectTimeoutError = 599
}
