//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsStrings.swift
//
//  Created by Nacho Soto on 08/7/23.

import Foundation

// swiftlint:disable identifier_name

enum PaywallsStrings {

    case warming_up_eligibility_cache(products: Set<String>)
    case warming_up_images(imageURLs: Set<URL>)
    case error_prefetching_image(URL, Error)

}

extension PaywallsStrings: LogMessage {

    var description: String {
        switch self {
        case let .warming_up_eligibility_cache(products):
            return "Warming up intro eligibility cache for \(products.count) products"

        case let .warming_up_images(imageURLs):
            return "Warming up paywall images: \(imageURLs)"

        case let .error_prefetching_image(url, error):
            return "Error pre-fetching paywall image '\(url)': \((error as NSError).description)"
        }
    }

    var category: String { return "paywalls" }

}
