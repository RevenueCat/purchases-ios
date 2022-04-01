//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPResponse.swift
//
//  Created by César de la Vega on 4/19/21.
//

import Foundation

struct HTTPResponse {

    typealias Body = [String: Any]

    let statusCode: HTTPStatusCode
    let jsonObject: Body

}

extension HTTPResponse: CustomStringConvertible {

    var description: String {
        "HTTPResponse(statusCode: \(self.statusCode.rawValue), jsonObject: \(self.jsonObject.description))"
    }

}
