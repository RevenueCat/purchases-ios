//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPStatusCodes.swift
//
//  Created by César de la Vega on 4/19/21.
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
