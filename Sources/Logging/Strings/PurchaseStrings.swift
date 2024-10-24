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
    case purchases_orchestrator_init(PurchasesOrchestrator)
    case purchases_orchestrator_deinit(PurchasesOrchestrator)
    case updating_all_caches
    case not_updating_caches_while_products_are_in_progress
    case cannot_purchase_product_appstore_configuration_error
    case entitlements_revoked_syncing_purchases(productIdentifiers: [String])
    case entitlement_expired_outside_grace_period(expiration: Date, reference: Date)
    case finishing_transaction(StoreTransactionType)
    case finish_transaction_skipped_because_its_missing_in_non_subscriptions(StoreTransactionType,
                                                                             [NonSubscriptionTransaction])
    case purchasing_with_observer_mode_and_finish_transactions_false_warning
    case paymentqueue_revoked_entitlements_for_product_identifiers(productIdentifiers: [String])
    case paymentqueue_adding_payment(SKPaymentQueue, SKPayment)
    case paymentqueue_removed_transaction(SKPaymentTransactionObserver,
                                          SKPaymentTransaction)
    case paymentqueue_removed_transaction_no_callbacks_found(SKPaymentTransactionObserver,
                                                             SKPaymentTransaction,
                                                             observerMode: Bool)
    case paymentqueue_updated_transaction(SKPaymentTransactionObserver,
                                          SKPaymentTransaction)
    case presenting_code_redemption_sheet
    case unable_to_present_redemption_sheet
    case purchases_synced
    case purchasing_product(StoreProduct, Package?, PromotionalOffer.SignedData?, [String: String]?)

    case purchased_product(productIdentifier: String)
    case product_purchase_failed(productIdentifier: String, error: Error)
    case skpayment_missing_from_skpaymenttransaction
    case skpayment_missing_product_identifier
    case sktransaction_missing_transaction_date(SKPaymentTransactionState)
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
    case missing_cached_customer_info
    case sk2_transactions_update_received_transaction(productID: String)
    case transaction_poster_handling_transaction(transactionID: String,
                                                 productID: String,
                                                 transactionDate: Date,
                                                 offeringID: String?,
                                                 placementID: String?,
                                                 paywallSessionID: UUID?)
    case caching_presented_offering_identifier(offeringID: String, productID: String)
    case payment_queue_wrapper_delegate_call_sk1_enabled
    case restorepurchases_called_with_allow_sharing_appstore_account_false
    case sk2_observer_mode_error_processing_transaction(Error)

}

extension PurchaseStrings: LogMessage {

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

        case let .purchases_orchestrator_init(instance):
            return "PurchasesOrchestrator.init: \(Strings.objectDescription(instance))"

        case let .purchases_orchestrator_deinit(instance):
            return "PurchasesOrchestrator.deinit: \(Strings.objectDescription(instance))"

        case .updating_all_caches:
            return "Updating all caches"

        case .not_updating_caches_while_products_are_in_progress:
            return "Detected purchase in progress: will skip cache updates"

        case .cannot_purchase_product_appstore_configuration_error:
            return "Could not purchase SKProduct. " +
            "There is a problem with your configuration in App Store Connect. " +
            "More info here: https://errors.rev.cat/configuring-products"

        case .entitlements_revoked_syncing_purchases(let productIdentifiers):
            return "Entitlements revoked for product " +
            "identifiers: \(productIdentifiers). \nsyncing purchases"

        case let .entitlement_expired_outside_grace_period(expiration, reference):
            return "Entitlement is no longer active (expired \(expiration)) " +
            "and it's outside grace period window (last updated \(reference))"

        case let .finishing_transaction(transaction):
            return "Finishing transaction '\(transaction.transactionIdentifier)' " +
            "for product '\(transaction.productIdentifier)'"

        case let .finish_transaction_skipped_because_its_missing_in_non_subscriptions(transaction, nonSubscriptions):
            return "Transaction '\(transaction.transactionIdentifier)' will not be finished: " +
            "it's a non-subscription and it's missing in CustomerInfo list: \(nonSubscriptions)"

        case .purchasing_with_observer_mode_and_finish_transactions_false_warning:
            return "purchasesAreCompletedBy is not set to .myApp and " +
            "purchase has been initiated. RevenueCat will not finish the " +
            "transaction, are you sure you want to do this?"

        case .paymentqueue_revoked_entitlements_for_product_identifiers(let productIdentifiers):
            return "PaymentQueue didRevokeEntitlementsForProductIdentifiers: \(productIdentifiers)"

        case let .paymentqueue_adding_payment(queue, payment):
            return "Adding payment for product '\(payment.productIdentifier)'. " +
            "\(queue.transactions.count) transactions already in the queue."

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

        case let .paymentqueue_removed_transaction_no_callbacks_found(observer, transaction, observerMode):
            // Transactions finished with observer mode won't have a callback because they're being finished
            // by the developer and not our SDK.
            let shouldIncludeCompletionBlockMessage = !observerMode

            let prefix = "\(observer.debugName) removedTransaction for \(transaction.payment.productIdentifier) " +
            "but no callbacks to notify."
            let completionBlockMessage = "If the purchase completion block is not being invoked after this, " +
            "it likely means that some other code outside of the RevenueCat SDK is calling " +
            "`SKPaymentQueue.finishTransaction`, which is interfering with RevenueCat purchasing state handling."

            return shouldIncludeCompletionBlockMessage
                ? prefix + "\n" + completionBlockMessage
                : prefix

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

        case let .purchasing_product(product, package, discount, metadata):
            var message = "Purchasing Product '\(product.productIdentifier)'"
            if let package = package {
                message += " from package in Offering " +
                "'\(package.presentedOfferingContext.offeringIdentifier)'"
            }
            if let discount = discount {
                message += " with Offer '\(discount.identifier)'"
            }
            if let metadata = metadata {
                message += " with metadata: \(metadata)"
            }
            return message

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

        case let .sktransaction_missing_transaction_date(transactionState):
            return """
            The SKPaymentTransaction has a nil value for transaction date - this is a bug in StoreKit.
            Unix Epoch will be used instead for the transaction within the app.
            Transactions in the backend and in webhooks are unaffected and will have the correct timestamps.
            Transaction state: \(transactionState)
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
        case .missing_cached_customer_info:
            return "Requested a cached CustomerInfo but it's not available."

        case let .sk2_transactions_update_received_transaction(productID):
            return "StoreKit.Transaction.updates: received transaction for product '\(productID)'"

        case let .transaction_poster_handling_transaction(transactionID,
                                                          productID,
                                                          date,
                                                          offeringID,
                                                          placementID,
                                                          paywallSessionID):
            var message = "TransactionPoster: handling transaction '\(transactionID)' " +
            "for product '\(productID)' (date: \(date))"

            if let offeringIdentifier = offeringID {
                message += " in Offering '\(offeringIdentifier)'"
            }

            if let placementIdentifier = placementID {
                message += " with Placement '\(placementIdentifier)'"
            }

            if let paywallSessionID {
                message += " with paywall session '\(paywallSessionID)'"
            }

            return message

        case let .caching_presented_offering_identifier(offeringID, productID):
            return "Caching presented offering identifier '\(offeringID)' for product '\(productID)'"

        case .payment_queue_wrapper_delegate_call_sk1_enabled:
            return "Unexpectedly received PaymentQueueWrapperDelegate call with SK1 enabled"

        case .restorepurchases_called_with_allow_sharing_appstore_account_false:
            return "allowSharingAppStoreAccount is set to false and restorePurchases has been called. " +
            "Are you sure you want to do this?"
        case let .sk2_observer_mode_error_processing_transaction(error):
            return "RevenueCat could not process transaction completed by your app: \(error)"
        }
    }

    var category: String { return "purchases" }

}

private extension SKPaymentTransactionObserver {

    var debugName: String {
        return Strings.objectDescription(self)
    }

}
