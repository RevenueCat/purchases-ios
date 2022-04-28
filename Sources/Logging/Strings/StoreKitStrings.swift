//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitStrings.swift
//
//  Created by Juanpe Catalán on 8/9/21.

import Foundation

// swiftlint:disable identifier_name
enum StoreKitStrings {

    case skrequest_failed(error: Error)

    case skproductsrequest_failed(error: Error)

    case skproductsrequest_timed_out(after: Int)

    case skproductsrequest_finished

    case skproductsrequest_received_response

    case skunknown_payment_mode(String)

    case sk2_purchasing_added_promotional_offer_option(String)

    case sk2_unknown_product_type(String)

    case sk1_no_known_product_type

    case sk1_discount_missing_locale

}

extension StoreKitStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case .skrequest_failed(let error):
            return "SKRequest failed: \(error.localizedDescription)"

        case .skproductsrequest_failed(let error):
            return "SKProductsRequest failed! error: \(error.localizedDescription)"

        case .skproductsrequest_timed_out(let afterTimeInSeconds):
            return "SKProductsRequest took longer than \(afterTimeInSeconds) seconds, " +
            "cancelling request and returning an empty set. This seems to be an App Store quirk. " +
            "If this is happening to you consistently, you might want to try using a new Sandbox account. " +
            "More information: https://rev.cat/skproductsrequest-hangs"

        case .skproductsrequest_finished:
            return "SKProductsRequest did finish"

        case .skproductsrequest_received_response:
            return "SKProductsRequest request received response"

        case let .skunknown_payment_mode(name):
            return "Unrecognized PaymentMode: \(name)"

        case let .sk2_purchasing_added_promotional_offer_option(discountIdentifier):
            return "Adding Product.PurchaseOption for discount '\(discountIdentifier)'"

        case let .sk2_unknown_product_type(type):
            return "Product.ProductType '\(type)' unknown, the product type will be undefined."

        case .sk1_no_known_product_type:
            return "This StoreProduct represents an SK1 product, the type of product cannot be determined, " +
            "the value will be undefined. Use `StoreProduct.productCategory` instead."

        case .sk1_discount_missing_locale:
            return "There is an issue with the App Store, this SKProductDiscount is missing a Locale - " +
            "The current device Locale will be used instead."
        }
    }

}
