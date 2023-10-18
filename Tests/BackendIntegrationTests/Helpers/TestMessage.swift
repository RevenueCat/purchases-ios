//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Messages.swift
//
//  Created by Nacho Soto on 6/13/23.

import Foundation

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

// swiftlint:disable identifier_name

enum TestMessage: LogMessage {

    case expiring_subscription(productID: String)
    case expire_subscription_failed(Error)

    case resetting_purchases_singleton
    case removing_receipt(URL)
    case error_removing_url(URL, Error)
    case receipt_content(String)
    case unable_parse_receipt_without_sdk
    case error_parsing_receipt(Error)

}

extension TestMessage {

    var description: String {
        switch self {
        case let .expiring_subscription(productID):
            return "Expiring subscription for product '\(productID)'"

        case let .expire_subscription_failed(error):
            return """
                Failed testSession.expireSubscription, this is probably an Xcode bug.
                Test will now wait for expiration instead of triggering it.
                Error: \(error.localizedDescription)
                """

        case .resetting_purchases_singleton:
            return "Resetting Purchases.shared"

        case let .removing_receipt(url):
            return "Removing receipt from url: \(url)"

        case let .error_removing_url(url, error):
            return "Error attempting to remove receipt URL '\(url)': \(error)"

        case let .receipt_content(receipt):
            return "Receipt content:\n\(receipt)"

        case .unable_parse_receipt_without_sdk:
            return "Can't print receipt when purchases isn't configured"

        case let .error_parsing_receipt(error):
            return "Error parsing local receipt: \(error)"
        }
    }

    var category: String { return "IntegrationTests" }

}
