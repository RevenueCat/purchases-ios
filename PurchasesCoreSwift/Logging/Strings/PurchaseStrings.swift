//
//  PurchaseStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
@objc(RCPurchaseStrings) public class PurchaseStrings: NSObject {
    @objc public var cannot_purchase_product_appstore_configuration_error: String { "Could not purchase SKProduct. " +
        "There is a problem with your configuration in App Store Connect. " +
        "More info here: https://errors.rev.cat/configuring-products" }
    @objc public var entitlements_revoked_syncing_purchases: String { "Entitlements revoked for product " +
        "identifiers: %@. \nsyncing purchases" }
    @objc public var finishing_transaction: String { "Finishing transaction %@ %@ (%@)" }
    @objc public var purchasing_with_observer_mode_and_finish_transactions_false_warning: String { "Observer mode is " +
        "active (finishTransactions is set to false) and purchase has been initiated. RevenueCat will not finish the " +
        "transaction, are you sure you want to do this?" }
    @objc public var paymentqueue_removedtransaction: String {
        "PaymentQueue removedTransaction: %@ %@ (%@ %@) %@ - %d"
    }
    @objc public var paymentqueue_revoked_entitlements_for_product_identifiers: String { "PaymentQueue " +
        "didRevokeEntitlementsForProductIdentifiers: %@" }
    @objc public var paymentqueue_updatedtransaction: String { "PaymentQueue updatedTransaction: %@ %@ (%@) %@ - %d" }
    @objc public var presenting_code_redemption_sheet_unavailable: String { "Attempted to present code redemption " +
        "sheet, but it's not available on this device." }
    @objc public var presenting_code_redemption_sheet: String { "Presenting code redemption sheet." }
    @objc public var purchases_synced: String { "Purchases synced." }
    @objc public var purchasing_product_from_package: String { "Purchasing product from package  - %@ in Offering %@" }
    @objc public var purchasing_product: String { "Purchasing product - %@" }
    @objc public var skpayment_missing_from_skpaymenttransaction: String { "There is a problem with the " +
        "SKPaymentTransaction missing an SKPayment - this is an issue with the App Store." }
    @objc public var skpayment_missing_product_identifier: String { "There is a problem with the SKPayment missing " +
        "a product identifier - this is an issue with the App Store." }
}
