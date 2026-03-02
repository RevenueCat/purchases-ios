//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdHTTPRequestPath.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

extension HTTPRequest.AdPath: EventsHTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://a.revenue.cat")!

    var name: String {
        switch self {
        case .postEvents:
            return "post_ad_events"
        }
    }

}
