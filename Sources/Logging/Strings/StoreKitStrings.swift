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
import StoreKit

// swiftlint:disable identifier_name
enum StoreKitStrings {

    case sk_receipt_request_started

    case sk_receipt_request_finished

    case skrequest_failed(NSError)

    case store_products_request_failed(NSError)

    case skproductsrequest_timed_out(after: Int)

    case store_product_request_finished

    case store_product_request_received_response

    case skunknown_payment_mode(String)

    case sk1_product_with_sk2_enabled

    case sk2_purchasing_added_promotional_offer_option(String)

    case sk2_purchasing_added_winback_offer_option(String)

    case sk2_purchasing_added_uuid_option(UUID)

    case sk2_unknown_product_type(String)

    case sk1_no_known_product_type

    case sk1_unknown_transaction_state(SKPaymentTransactionState)

    case unknown_sk2_product_discount_type(rawValue: String)

    case sk1_discount_missing_locale

    case no_cached_products_starting_store_products_request(identifiers: Set<String>)

    case sk1_payment_queue_too_many_transactions(count: Int, isSandbox: Bool)

    case sk1_finish_transaction_called_with_existing_completion(SKPaymentTransaction)

    case sk1_product_request_too_slow

    case sk2_product_request_too_slow

    case sk2_observing_transaction_updates

    case sk2_observing_purchase_intents

    case sk2_unknown_environment(String)

    case sk2_error_encoding_receipt(Error)

    case sk2_error_fetching_app_transaction(Error)

    case sk2_error_fetching_subscription_status(subscriptionGroupId: String, Error)

    case sk2_app_transaction_unavailable

    case sk2_unverified_transaction(identifier: String, Error)

    case sk2_unverified_renewal_info(productIdentifier: String)

    case sk2_receipt_missing_purchase(transactionId: String)

    #if DEBUG

    case sk1_wrapper_notifying_delegate_of_existing_transactions(count: Int)

    #endif

    case could_not_defer_store_messages(Error)

    case error_displaying_store_message(Error)

    case unknown_storekit_error(Error)

    case skunknown_purchase_result(String)

}

extension StoreKitStrings: LogMessage {

    var description: String {
        switch self {
        case .sk_receipt_request_started:
            return "SKReceiptRefreshRequest started"

        case .sk_receipt_request_finished:
            return "SKReceiptRefreshRequest finished"

        case .skrequest_failed(let error):
            return "SKRequest failed: \(error.description)"

        case .store_products_request_failed(let error):
            return "Store products request failed! Error: \(error.description)"

        case .skproductsrequest_timed_out(let afterTimeInSeconds):
            return "SKProductsRequest took longer than \(afterTimeInSeconds) seconds, " +
            "cancelling request and returning an empty set. This seems to be an App Store quirk. " +
            "If this is happening to you consistently, you might want to try using a new Sandbox account. " +
            "More information: https://rev.cat/skproductsrequest-hangs"

        case .store_product_request_finished:
            return "Store products request finished"

        case .store_product_request_received_response:
            return "Store products request received response"

        case let .skunknown_payment_mode(name):
            return "Unrecognized PaymentMode: \(name)"

        case .sk1_product_with_sk2_enabled:
            return "This StoreProduct represents an SK1 product, but SK2 was expected."

        case let .sk2_purchasing_added_promotional_offer_option(discountIdentifier):
            return "Adding Product.PurchaseOption for discount '\(discountIdentifier)'"

        case let .sk2_purchasing_added_winback_offer_option(winBackOfferID):
            return "Adding Product.PurchaseOption for win-back offer with ID '\(winBackOfferID)'"

        case let .sk2_purchasing_added_uuid_option(uuid):
            return "Adding Product.PurchaseOption for .appAccountToken '\(uuid)'"

        case let .sk2_unknown_product_type(type):
            return "Product.ProductType '\(type)' unknown, the product type will be undefined."

        case .sk1_no_known_product_type:
            return "This StoreProduct represents an SK1 product, the type of product cannot be determined, " +
            "the value will be undefined. Use `StoreProduct.productCategory` instead."

        case let .sk1_unknown_transaction_state(state):
            return "Received unknown transaction state: \(state.rawValue)"

        case .unknown_sk2_product_discount_type(let rawValue):
            return "Failed to create StoreProductDiscount.DiscountType with unknown value: \(rawValue)"

        case .sk1_discount_missing_locale:
            return "There is an issue with the App Store, this SKProductDiscount is missing a Locale - " +
            "The current device Locale will be used instead."

        case .no_cached_products_starting_store_products_request(let identifiers):
            return "No existing products cached, starting store products request for: \(identifiers)"

        case let .sk1_payment_queue_too_many_transactions(count, isSandbox):
            let messageSuffix = isSandbox
            ? "This high number is unexpected and is likely due to using an old sandbox account on a new device. " +
            "If this is impacting performance, using a new sandbox account is recommended."
            : "This is a very high number and might impact performance."

            return "SKPaymentQueue sent \(count) updated transactions. " + messageSuffix

        case let .sk1_finish_transaction_called_with_existing_completion(transaction):
            return "StoreKit1Wrapper.finishTransaction was called for '\(transaction.productIdentifier ?? "")' " +
            "but found an existing completion block."

        case .sk1_product_request_too_slow:
            return "StoreKit 1 product request took longer than expected"

        case .sk2_product_request_too_slow:
            return "StoreKit 2 product request took longer than expected"

        case .sk2_observing_transaction_updates:
            return "Observing StoreKit.Transaction.updates"

        case .sk2_observing_purchase_intents:
            return "Observing StoreKit.PurchaseIntent.intents"

        case let .sk2_unknown_environment(environment):
            return "Unrecognized StoreKit Environment: \(environment)"

        case let .sk2_error_encoding_receipt(error):
            return "Error encoding SK2 receipt: '\(error)'"

        case let .sk2_error_fetching_app_transaction(error):
            return "Error fetching AppTransaction: '\(error)'"

        case let .sk2_error_fetching_subscription_status(subscriptionGroupId, error):
            return "Error fetching status for subscription group with id '\(subscriptionGroupId)': '\(error)'"

        case .sk2_app_transaction_unavailable:
            return "Not fetching AppTransaction because it is not available"

        case let .sk2_unverified_transaction(id, error):
            return "Found unverified transaction with ID: '\(id)' Error: '\(error)'"

        case let .sk2_unverified_renewal_info(productIdentifier):
            return "Found unverified renewal info for product with identifier: '\(productIdentifier)'"

        case let .sk2_receipt_missing_purchase(transactionId):
            return "SK2 receipt is still missing transaction with id '\(transactionId)'"

        #if DEBUG
        case let .sk1_wrapper_notifying_delegate_of_existing_transactions(count):
            return "StoreKit1Wrapper: sending delegate \(count) existing transactions " +
            "for Integration Tests."
        #endif

        case let .could_not_defer_store_messages(error):
            return "Tried to defer store messages but an error occured: '\(error)'."

        case let .error_displaying_store_message(error):
            return "Error displaying StoreKit message: '\(error)'"

        case let .unknown_storekit_error(error):
            return "Unknown StoreKit error. Error: '\(error.localizedDescription)'"

        case let .skunknown_purchase_result(name):
            return "Unrecognized Product.PurchaseResult: \(name)"
        }
    }

    var category: String { return "store_kit" }

}
