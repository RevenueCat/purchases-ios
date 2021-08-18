//
//  HTTPResponse.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 4/19/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

struct HTTPResponse: CustomStringConvertible {

    let statusCode: Int
    let jsonObject: [String: Any]?

    var description: String {
        "HTTPResponse(statusCode: \(statusCode), jsonObject: \(jsonObject?.description ?? ""))"
    }

}
