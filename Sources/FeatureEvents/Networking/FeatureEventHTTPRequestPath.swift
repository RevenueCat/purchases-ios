//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEventHTTPRequestPath.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation

extension HTTPRequest.FeatureEventPath: EventHTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://api-paywalls.revenuecat.com")!

    var relativePath: String {
        switch self {
        case .postEvents:
            return "/v1/events"
        }
    }

    var name: String {
        switch self {
        case .postEvents:
            return "post_feature_events"
        }
    }

}
