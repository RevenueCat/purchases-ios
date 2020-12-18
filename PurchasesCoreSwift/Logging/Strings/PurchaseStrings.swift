//
//  PurchaseStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCPurchaseStrings) public class PurchaseStrings: NSObject {
    @objc public var cannot_purchase_product: String { "Could not purchase SKProduct. There is a problem with your configuration in App Store Connect. More info here: http://errors.rev.cat/products-empty" }  //appleWarning
    @objc public var entitlements_revoked: String { "Entitlements revoked for product identifiers: %@. \nsyncing purchases" } //debug
    @objc public var finishing_transaction: String { "Finishing transaction %@ %@ (%@)" }  //purchase
    @objc public var observer_active_finishtransaction_false: String { "Observer mode is active (finishTransactions is set to false) and purchase has been initiated. RevenueCat will not finish the transaction, are you sure you want to do this?" } //warning
    @objc public var paymentqueue_removedtransaction: String { "PaymentQueue removedTransaction: %@ %@ (%@ %@) %@ - %d" }  //debug
    @objc public var paymentqueue_revoke_entitlement: String { "PaymentQueue didRevokeEntitlementsForProductIdentifiers: %@" } //debug
    @objc public var paymentqueue_updatedtransaction: String { "PaymentQueue updatedTransaction: %@ %@ (%@) %@ - %d" } //debug
    @objc public var presenting_code_redemption_sheet_unavailable: String { "Attempted to present code redemption sheet, but it's not available on this device." }
    @objc public var presenting_code_redemption_sheet: String { "Presenting code redemption sheet" } //debug
    @objc public var purchases_synced: String { "Purchases synced" } //debug
    @objc public var purchasing_product_from_package: String { "Purchasing product from package  - %@ in Offering %@" }  //purchase
    @objc public var purchasing_product: String { "Purchasing product - %@" } //purchase
    @objc public var skpayment_missing_from_skpaymenttransaction: String { "There is a problem with the SKPaymentTransaction missing an SKPayment - this is an issue with the App Store." } //appleWarning
    @objc public var skpayment_missing_product_identifier: String { "There is a problem with the SKPayment missing a product identifier - this is an issue with the App Store." }  //appleWarning
    @objc public var skproduct_missing_product_identifier: String { "Could not purchase SKProduct. The product identifier is missing on the SKProduct - this is an issue with the App Store." }  //appleWarning
}
