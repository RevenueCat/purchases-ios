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
enum PurchaseStrings: CustomStringConvertible {

    static let cannot_purchase_product_appstore_configuration_error = "Could not purchase SKProduct. " +
        "There is a problem with your configuration in App Store Connect. " +
        "More info here: https://errors.rev.cat/configuring-products"
    static let entitlements_revoked_syncing_purchases = "Entitlements revoked for product " +
        "identifiers: %@. \nsyncing purchases"
    static let finishing_transaction = "Finishing transaction %@ %@ (%@)"
    static let purchasing_with_observer_mode_and_finish_transactions_false_warning = "Observer mode is " +
        "active (finishTransactions is set to false) and purchase has been initiated. RevenueCat will not finish the " +
        "transaction, are you sure you want to do this?"
    static let paymentqueue_removedtransaction = "PaymentQueue removedTransaction: %@ %@ (%@ %@) %@ - %d"
    static let paymentqueue_revoked_entitlements_for_product_identifiers = "PaymentQueue " +
        "didRevokeEntitlementsForProductIdentifiers: %@"
    static let paymentqueue_updatedtransaction = "PaymentQueue updatedTransaction: %@ %@ (%@) %@ - %d"
    static let presenting_code_redemption_sheet = "Presenting code redemption sheet."
    static let purchases_synced = "Purchases synced."
    static let purchasing_product_from_package = "Purchasing product from package  - %@ in Offering %@"
    static let purchasing_product = "Purchasing product - %@"
    static let skpayment_missing_from_skpaymenttransaction = "There is a problem with the " +
        "SKPaymentTransaction missing an SKPayment - this is an issue with the App Store."
    static let skpayment_missing_product_identifier = "There is a problem with the SKPayment missing " +
        "a product identifier - this is an issue with the App Store."
    static let could_not_purchase_product_id_not_found = "makePurchase - Could not purchase SKProduct. " +
        "Couldn't find its product identifier. This is possibly an App Store quirk."
    static let product_identifier_nil = "Apple returned a product where the productIdentifier is nil, " +
        "this is possibly an App Store quirk"
    static let payment_identifier_nil = "Apple returned a payment where the productIdentifier is nil, " +
        "this is possibly an App Store quirk"
    static let purchases_nil = "Purchases has not been configured. Please call Purchases.configure()"
    static let purchases_delegate_set_multiple_times = "Purchases delegate has already been configured."
    static let purchases_delegate_set_to_nil = "Purchases delegate is being set to nil, " +
        "you probably don't want to do this."
    static let management_url_nil_opening_default = "managementURL is nil, opening Apple's subscription management page"

    case requested_products_not_found(request: SKRequest)

    var description: String {
        switch self {
        case .requested_products_not_found(let request):
            return "requested products not found for request: \(request)"
        }
    }
}
