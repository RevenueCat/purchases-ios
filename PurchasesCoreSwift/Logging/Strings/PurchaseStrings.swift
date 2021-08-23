//
//  PurchaseStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
class PurchaseStrings {

    var cannot_purchase_product_appstore_configuration_error: String { "Could not purchase SKProduct. " +
        "There is a problem with your configuration in App Store Connect. " +
        "More info here: https://errors.rev.cat/configuring-products" }
    var entitlements_revoked_syncing_purchases: String { "Entitlements revoked for product " +
        "identifiers: %@. \nsyncing purchases" }
    var finishing_transaction: String { "Finishing transaction %@ %@ (%@)" }
    var purchasing_with_observer_mode_and_finish_transactions_false_warning: String { "Observer mode is " +
        "active (finishTransactions is set to false) and purchase has been initiated. RevenueCat will not finish the " +
        "transaction, are you sure you want to do this?" }
    var paymentqueue_removedtransaction: String {
        "PaymentQueue removedTransaction: %@ %@ (%@ %@) %@ - %d"
    }
    var paymentqueue_revoked_entitlements_for_product_identifiers: String { "PaymentQueue " +
        "didRevokeEntitlementsForProductIdentifiers: %@" }
    var paymentqueue_updatedtransaction: String { "PaymentQueue updatedTransaction: %@ %@ (%@) %@ - %d" }
    var presenting_code_redemption_sheet: String { "Presenting code redemption sheet." }
    var purchases_synced: String { "Purchases synced." }
    var purchasing_product_from_package: String { "Purchasing product from package  - %@ in Offering %@" }
    var purchasing_product: String { "Purchasing product - %@" }
    var skpayment_missing_from_skpaymenttransaction: String { "There is a problem with the " +
        "SKPaymentTransaction missing an SKPayment - this is an issue with the App Store." }
    var skpayment_missing_product_identifier: String { "There is a problem with the SKPayment missing " +
        "a product identifier - this is an issue with the App Store." }
    var could_not_purchase_product_id_not_found: String { "makePurchase - Could not purchase SKProduct. " +
        "Couldn't find its product identifier. This is possibly an App Store quirk." }
    var product_identifier_nil: String {
        "Apple returned a product where the productIdentifier is nil, this is possibly an App Store quirk"
    }
    var payment_identifier_nil: String {
        "Apple returned a payment where the productIdentifier is nil, this is possibly an App Store quirk"
    }

    var purchases_nil: String { "Purchases has not been configured. Please call Purchases.configure()" }

    var purchases_delegate_set_multiple_times: String { "Purchases delegate has already been configured." }

    var purchases_delegate_set_to_nil: String {
        "Purchases delegate is being set to nil, you probably don't want to do this."
    }

}
