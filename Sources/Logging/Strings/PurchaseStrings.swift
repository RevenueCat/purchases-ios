//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation
import StoreKit

// swiftlint:disable identifier_name

enum PurchaseStrings {

    case storekit1_wrapper_init(StoreKit1Wrapper)
    case storekit1_wrapper_deinit(StoreKit1Wrapper)
    case device_cache_init(DeviceCache)
    case device_cache_deinit(DeviceCache)
    case cannot_purchase_product_appstore_configuration_error
    case entitlements_revoked_syncing_purchases(productIdentifiers: [String])
    case finishing_transaction(StoreTransactionType)
    case purchasing_with_observer_mode_and_finish_transactions_false_warning
    case paymentqueue_revoked_entitlements_for_product_identifiers(productIdentifiers: [String])
    case paymentqueue_removed_transaction(_ observer: SKPaymentTransactionObserver,
                                          _ transaction: SKPaymentTransaction)
    case paymentqueue_updated_transaction(_ observer: SKPaymentTransactionObserver,
                                          _ transaction: SKPaymentTransaction)
    case presenting_code_redemption_sheet
    case unable_to_present_redemption_sheet
    case purchases_synced
    case purchasing_product(StoreProduct)
    case purchasing_product_from_package(StoreProduct, Package)
    case purchasing_product_with_offer(StoreProduct, PromotionalOffer.SignedData)
    case purchasing_product_from_package_with_offer(StoreProduct, Package, PromotionalOffer.SignedData)
    case purchased_product(productIdentifier: String)
    case product_purchase_failed(productIdentifier: String, error: Error)
    case skpayment_missing_from_skpaymenttransaction
    case skpayment_missing_product_identifier
    case sktransaction_missing_transaction_date
    case sktransaction_missing_transaction_identifier
    case could_not_purchase_product_id_not_found
    case payment_identifier_nil
    case purchases_nil
    case purchases_delegate_set_multiple_times
    case purchases_delegate_set_to_nil
    case requested_products_not_found(request: SKRequest)
    case promo_purchase_product_not_found(productIdentifier: String)
    case callback_not_found_for_request(request: SKRequest)
    case duplicate_refund_request(details: String)
    case failed_refund_request(details: String)
    case unknown_refund_request_error(details: String)
    case unknown_refund_request_error_type(details: String)
    case unknown_refund_request_status
    case product_unpurchased_or_missing
    case transaction_unverified(productID: String, errorMessage: String)
    case unknown_purchase_result(result: String)
    case begin_refund_no_entitlement_found(entitlementID: String?)
    case begin_refund_no_active_entitlement
    case begin_refund_multiple_active_entitlements
    case begin_refund_customer_info_error(entitlementID: String?)
    case cached_app_user_id_deleted
    case missing_cached_customer_info
    case sk1_purchase_too_slow
    case sk2_purchase_too_slow

}

extension PurchaseStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .storekit1_wrapper_init(instance):
            return "StoreKit1Wrapper.init: \(Strings.objectDescription(instance))"

        case let .storekit1_wrapper_deinit(instance):
            return "StoreKit1Wrapper.deinit: \(Strings.objectDescription(instance))"

        case let .device_cache_init(instance):
            return "DeviceCache.init: \(Strings.objectDescription(instance))"

        case let .device_cache_deinit(instance):
            return "DeviceCache.deinit: \(Strings.objectDescription(instance))"

        case .cannot_purchase_product_appstore_configuration_error:
            return "Could not purchase SKProduct. " +
            "There is a problem with your configuration in App Store Connect. " +
            "More info here: https://errors.rev.cat/configuring-products"

        case .entitlements_revoked_syncing_purchases(let productIdentifiers):
            return "Entitlements revoked for product " +
            "identifiers: \(productIdentifiers). \nsyncing purchases"

        case let .finishing_transaction(transaction):
            return "Finishing transaction '\(transaction.transactionIdentifier)' " +
            "for product '\(transaction.productIdentifier)'"

        case .purchasing_with_observer_mode_and_finish_transactions_false_warning:
            return "Observer mode is active (finishTransactions is set to false) and " +
            "purchase has been initiated. RevenueCat will not finish the " +
            "transaction, are you sure you want to do this?"

        case .paymentqueue_revoked_entitlements_for_product_identifiers(let productIdentifiers):
            return "PaymentQueue didRevokeEntitlementsForProductIdentifiers: \(productIdentifiers)"

        case let .paymentqueue_removed_transaction(observer, transaction):
            let errorUserInfo = (transaction.error as NSError?)?.userInfo ?? [:]

            return "\(observer.debugName) removedTransaction: \(transaction.payment.productIdentifier) " +
            [
                transaction.transactionIdentifier,
                transaction.original?.transactionIdentifier,
                (transaction.error?.localizedDescription).map { "(\($0))" },
                !errorUserInfo.isEmpty ? errorUserInfo.description : nil,
                transaction.transactionState.rawValue.description
            ]
                .compactMap { $0 }
                .joined(separator: " ")

        case let .paymentqueue_updated_transaction(observer, transaction):
            return "\(observer.debugName) updatedTransaction: \(transaction.payment.productIdentifier) " +
            [
                transaction.transactionIdentifier,
                (transaction.error?.localizedDescription).map { "(\($0))" },
                transaction.original?.transactionIdentifier ?? nil,
                transaction.transactionState.rawValue.description
            ]
                .compactMap { $0 }
                .joined(separator: " ")

        case .presenting_code_redemption_sheet:
            return "Presenting code redemption sheet."

        case .unable_to_present_redemption_sheet:
            return "SKPaymentQueue.presentCodeRedemptionSheet is not available in the current platform, " +
            "this is an Apple bug."

        case .purchases_synced:
            return "Purchases synced."

        case let .purchasing_product(product):
            return "Purchasing Product '\(product.productIdentifier)'"

        case let .purchasing_product_from_package(product, package):
            return "Purchasing Product '\(product.productIdentifier)' from package " +
            "in Offering '\(package.offeringIdentifier)'"

        case let .purchasing_product_with_offer(product, discount):
            return "Purchasing Product '\(product.productIdentifier)' with Offer '\(discount.identifier)'"

        case let .purchasing_product_from_package_with_offer(product, package, discount):
            return "Purchasing Product '\(product.productIdentifier)' from package in Offering " +
            "'\(package.offeringIdentifier)' with Offer '\(discount.identifier)'"

        case let .purchased_product(productIdentifier):
            return "Purchased product - '\(productIdentifier)'"

        case let .product_purchase_failed(productIdentifier, error):
            return "Product purchase for '\(productIdentifier)' failed with error: \(error)"

        case .skpayment_missing_from_skpaymenttransaction:
            return """
            The SKPaymentTransaction has a nil value for SKPayment - this is an bug in StoreKit.
            Transactions in the backend and in webhooks are unaffected.
            """

        case .skpayment_missing_product_identifier:
            return "There is a problem with the SKPayment missing " +
            "a product identifier - this is an issue with the App Store."

        case .sktransaction_missing_transaction_date:
            return """
            The SKPaymentTransaction has a nil value for transaction date - this is a bug in StoreKit.
            Unix Epoch will be used instead for the transaction within the app.
            Transactions in the backend and in webhooks are unaffected and will have the correct timestamps.
            """

        case .sktransaction_missing_transaction_identifier:
            return """
            The SKPaymentTransaction has a nil value for transaction identifier - this is a bug in StoreKit.
            Transactions in the backend and in webhooks are unaffected and will have the correct identifier.
            """

        case .could_not_purchase_product_id_not_found:
            return "makePurchase - Could not purchase SKProduct. " +
            "Couldn't find its product identifier. This is possibly an App Store quirk."

        case .payment_identifier_nil:
            return "Apple returned a payment where the productIdentifier is nil, " +
            "this is possibly an App Store quirk"

        case .purchases_nil:
            return "Purchases has not been configured. Please call Purchases.configure()"

        case .purchases_delegate_set_multiple_times:
            return "Purchases delegate has already been configured."

        case .purchases_delegate_set_to_nil:
            return "Purchases delegate is being set to nil, " +
            "you probably don't want to do this."

        case .requested_products_not_found(let request):
            return "requested products not found for request: \(request)"

        case let .promo_purchase_product_not_found(productIdentifier):
            return "Unable to perform promotional purchase from App Store: product '\(productIdentifier)' not found"

        case .callback_not_found_for_request(let request):
            return "callback not found for failing request: \(request)"

        case .duplicate_refund_request(let details):
            return "Refund already requested for this product and is either pending, already denied, " +
            "or already approved: \(details)"
        case .failed_refund_request(let details):
            return "Refund request submission failed: \(details)"
        case .unknown_refund_request_error_type(let details):
            return "Unknown RefundRequestError type from the AppStore: \(details)"
        case .unknown_refund_request_error(let details):
            return "Unknown error type returned from AppStore: \(details)"
        case .unknown_refund_request_status:
            return "Unknown RefundRequestStatus returned from AppStore"
        case .product_unpurchased_or_missing:
            return "Product hasn't been purchased or doesn't exist."
        case .transaction_unverified(let productID, let errorMessage):
            return "Transaction for productID \(productID) is unverified by AppStore.\n" +
                "Verification error: \(errorMessage)"
        case let .unknown_purchase_result(result):
            return "Received unknown purchase result: \(result)"
        case .begin_refund_no_entitlement_found(let entitlementID):
            return "Could not find  \(entitlementID.flatMap { "entitlement with ID " + $0 } ?? "active entitlement")" +
                " for refund."
        case .begin_refund_no_active_entitlement:
            return "Could not begin refund request. No active entitlement."
        case .begin_refund_multiple_active_entitlements:
            return "Could not begin refund request. There are multiple active entitlements. Use" +
                " `beginRefundRequest(forEntitlement:)` to specify a single entitlement instead."
        case .begin_refund_customer_info_error(let entitlementID):
            return "Failed to get CustomerInfo to proceed with refund for " +
                "\(entitlementID.flatMap { "entitlement with ID " + $0 } ?? "active entitlement")."
        case .cached_app_user_id_deleted:
            return """
                [\(Logger.frameworkDescription)] - Cached appUserID has been deleted from user defaults.
                This leaves the SDK in an undetermined state. Please make sure that RevenueCat
                entries in user defaults don't get deleted by anything other than the SDK.
                More info: https://rev.cat/userdefaults-crash
                """

        case .missing_cached_customer_info:
            return "Requested a cached CustomerInfo but it's not available."

        case .sk1_purchase_too_slow:
            return "StoreKit 1 purchase took longer than expected"

        case .sk2_purchase_too_slow:
            return "StoreKit 2 purchase took longer than expected"
        }
    }

}

private extension SKPaymentTransactionObserver {

    var debugName: String {
        return Strings.objectDescription(self)
    }

}
