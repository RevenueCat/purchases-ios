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

    case cannot_purchase_product_appstore_configuration_error
    case entitlements_revoked_syncing_purchases(productIdentifiers: [String])
    case finishing_transaction(transaction: SKPaymentTransaction)
    case purchasing_with_observer_mode_and_finish_transactions_false_warning
    case paymentqueue_removedtransaction(transaction: SKPaymentTransaction)
    case paymentqueue_revoked_entitlements_for_product_identifiers(productIdentifiers: [String])
    case paymentqueue_updatedtransaction(transaction: SKPaymentTransaction)
    case presenting_code_redemption_sheet
    case purchases_synced
    case purchasing_product_from_package(productIdentifier: String, offeringIdentifier: String)
    case purchasing_product(productIdentifier: String)
    case skpayment_missing_from_skpaymenttransaction
    case skpayment_missing_product_identifier
    case could_not_purchase_product_id_not_found
    case product_identifier_nil
    case payment_identifier_nil
    case purchases_nil
    case purchases_delegate_set_multiple_times
    case purchases_delegate_set_to_nil
    case requested_products_not_found(request: SKRequest)
    case callback_not_found_for_request(request: SKRequest)
    case unable_to_get_intro_eligibility_for_user(error: Error)
    case duplicate_refund_request(details: String)
    case failed_refund_request(details: String)
    case unknown_refund_request_error(details: String)
    case unknown_refund_request_error_type(details: String)
    case unknown_refund_request_status
    case product_unpurchased_or_missing
    case transaction_unverified(productID: String, errorMessage: String)
    case begin_refund_request_unsupported
    case begin_refund_for_entitlement_nil_customer_info(entitlementID: String?)
    case begin_refund_no_entitlement_found(entitlementID: String?)
    case begin_refund_no_active_entitlement
    case begin_refund_customer_info_error(entitlementID: String?)
    case cached_app_user_id_deleted
    case check_eligibility_no_identifiers

}

extension PurchaseStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case .cannot_purchase_product_appstore_configuration_error:
            return "Could not purchase SKProduct. " +
            "There is a problem with your configuration in App Store Connect. " +
            "More info here: https://errors.rev.cat/configuring-products"

        case .entitlements_revoked_syncing_purchases(let productIdentifiers):
            return "Entitlements revoked for product " +
            "identifiers: \(productIdentifiers). \nsyncing purchases"

        case .finishing_transaction(let transaction):
            return "Finishing transaction \(transaction.payment.productIdentifier) " +
            "\(transaction.transactionIdentifier ?? "") " +
            "(\(transaction.original?.transactionIdentifier ?? ""))"

        case .purchasing_with_observer_mode_and_finish_transactions_false_warning:
            return "Observer mode is active (finishTransactions is set to false) and " +
            "purchase has been initiated. RevenueCat will not finish the " +
            "transaction, are you sure you want to do this?"

        case .paymentqueue_removedtransaction(let transaction):
            let errorUserInfo = (transaction.error as NSError?)?.userInfo ?? [:]
            return "PaymentQueue removedTransaction: \(transaction.payment.productIdentifier) " +
            "\(transaction.transactionIdentifier ?? "") " +
            "(\(transaction.original?.transactionIdentifier ?? "") " +
            "\(transaction.error?.localizedDescription ?? "") " +
            "\(!errorUserInfo.isEmpty ? errorUserInfo.description : "") - " +
            "\(transaction.transactionState.rawValue)"

        case .paymentqueue_revoked_entitlements_for_product_identifiers(let productIdentifiers):
            return "PaymentQueue " +
            "didRevokeEntitlementsForProductIdentifiers: \(productIdentifiers)"

        case .paymentqueue_updatedtransaction(let transaction):
            return "PaymentQueue updatedTransaction: \(transaction.payment.productIdentifier) " +
            "\(transaction.transactionIdentifier ?? "") " +
            "(\(transaction.error?.localizedDescription ?? "")) " +
            "\(transaction.original?.transactionIdentifier ?? "") - " +
            "\(transaction.transactionState.rawValue)"

        case .presenting_code_redemption_sheet:
            return "Presenting code redemption sheet."

        case .purchases_synced:
            return "Purchases synced."

        case let .purchasing_product_from_package(productIdentifier, offeringIdentifier):
            return "Purchasing product from package  - \(productIdentifier) in Offering \(offeringIdentifier)"

        case .purchasing_product(let productIdentifier):
            return "Purchasing product - \(productIdentifier)"

        case .skpayment_missing_from_skpaymenttransaction:
            return "There is a problem with the " +
            "SKPaymentTransaction missing an SKPayment - this is an issue with the App Store."

        case .skpayment_missing_product_identifier:
            return "There is a problem with the SKPayment missing " +
            "a product identifier - this is an issue with the App Store."

        case .could_not_purchase_product_id_not_found:
            return "makePurchase - Could not purchase SKProduct. " +
            "Couldn't find its product identifier. This is possibly an App Store quirk."

        case .product_identifier_nil:
            return "Apple returned a product where the productIdentifier is nil, " +
            "this is possibly an App Store quirk"

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

        case .callback_not_found_for_request(let request):
            return "callback not found for failing request: \(request)"

        case .unable_to_get_intro_eligibility_for_user(let error):
            return "Unable to get intro eligibility for appUserID: \(error.localizedDescription)"
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
            return "Transaction for productID \(productID) is unverified by AppStore. " +
                "Verification error \(errorMessage)"
        case .begin_refund_request_unsupported:
            return "Tried to call beginRefundRequest in a platform that doesn't support it!"
        case .begin_refund_for_entitlement_nil_customer_info(let entitlementID):
            return "Failed to get \(entitlementID.flatMap { "entitlement with ID " + $0 } ?? "active entitlement")" +
                " for refund. CustomerInfo is nil."
        case .begin_refund_no_entitlement_found(let entitlementID):
            return "Could not find  \(entitlementID.flatMap { "entitlement with ID " + $0 } ?? "active entitlement")" +
                " for refund."
        case .begin_refund_no_active_entitlement:
            return "Could not begin refund request. No active entitlement."
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
        case .check_eligibility_no_identifiers:
            return "Requested trial or introductory price eligibility with no identifiers. " +
            "This is likely a program error."
        }
    }

}
