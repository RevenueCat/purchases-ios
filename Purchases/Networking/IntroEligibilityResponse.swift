//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroEligibilityResponse.swift
//
//  Created by Joshua Liebowitz on 8/6/21.

import Foundation

// All parameters that are required to process the reponse from a GetIntroEligibility API call.
struct IntroEligibilityResponse {

    let maybeResponse: [String: Any]?
    let statusCode: Int
    let error: Error?
    let productIdentifiers: [String]
    let unknownEligibilityClosure: () -> [String: IntroEligibility]
    let completion: IntroEligibilityResponseHandler

}
