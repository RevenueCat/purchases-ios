//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GetIntroEligibilityResponse.swift
//
//  Created by Nacho Soto on 5/12/22.

import Foundation

struct GetIntroEligibilityResponse {

    var eligibilityByProductIdentifier: [String: IntroEligibilityStatus]

}

extension GetIntroEligibilityResponse: HTTPResponseBody {

    static func create(with data: Data) throws -> Self {
        let response = try [String: Bool?].create(with: data)

        return .init(
            eligibilityByProductIdentifier: response
                .mapValues {
                    if let status = $0 {
                        return status ? .eligible : .ineligible
                    } else {
                        return .unknown
                    }
                }
        )
    }

}
