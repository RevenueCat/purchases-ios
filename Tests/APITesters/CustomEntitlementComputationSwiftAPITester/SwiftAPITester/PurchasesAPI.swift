//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import RevenueCat_CustomEntitlementComputation
import StoreKit

func checkPurchasesAPI() {
    let purch = checkConfigure()!

    // initializers
    let finishTransactions: Bool = purch.finishTransactions
    let delegate: PurchasesDelegate? = purch.delegate
    let appUserID: String = purch.appUserID
    let isAnonymous: Bool = purch.isAnonymous

    print(finishTransactions, delegate!, appUserID, isAnonymous)

    checkStaticMethods()
    checkIdentity(purchases: purch)
    checkPurchasesPurchasingAPI(purchases: purch)
    checkPurchasesSupportAPI(purchases: purch)

    if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
        _ = Task<Void, Never> {
            await checkAsyncMethods(purchases: purch)
        }

        checkNonAsyncMethods(purch)
    }
}

var periodType: PeriodType!
var oType: PurchaseOwnershipType!
var logLevel: LogLevel!
func checkPurchasesEnums() {
    switch periodType! {
    case .normal,
         .intro,
         .trial:
        print(periodType!)
    @unknown default:
        fatalError()
    }

    switch oType! {
    case .purchased,
         .familyShared,
         .unknown:
        print(oType!)
    @unknown default:
        fatalError()
    }

    switch logLevel! {
    case .verbose,
         .debug,
         .info,
         .warn,
         .error:
        print(logLevel!)
    @unknown default:
        fatalError()
    }
}

private func checkStaticMethods() {
    let logHandler: (LogLevel, String) -> Void = { _, _ in }
    Purchases.logHandler = logHandler

    let canI: Bool = Purchases.canMakePayments()
    let version = Purchases.frameworkVersion
    let logLevel: LogLevel = Purchases.logLevel
    let proxyUrl: URL? = Purchases.proxyURL
    let forceUniversalAppStore: Bool = Purchases.forceUniversalAppStore
    let simulatesAskToBuyInSandbox: Bool = Purchases.simulatesAskToBuyInSandbox
    let sharedPurchases: Purchases = Purchases.shared
    let isPurchasesConfigured: Bool = Purchases.isConfigured

    print(canI, version, logLevel, proxyUrl!, forceUniversalAppStore, simulatesAskToBuyInSandbox,
          sharedPurchases, isPurchasesConfigured)
}

private func checkTypealiases(
    transaction: StoreTransaction?,
    customerInfo: CustomerInfo,
    userCancelled: Bool
) {
    let purchaseResultData: PurchaseResultData = (transaction: transaction,
                                                  customerInfo: customerInfo,
                                                  userCancelled: userCancelled)

    // swiftlint:disable:next line_length
    let purchaseCompletedBlock: PurchaseCompletedBlock = { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) -> Void in }

    let startPurchaseBlock: StartPurchaseBlock = { (_: PurchaseCompletedBlock) in }

    print(purchaseResultData,
          purchaseCompletedBlock,
          startPurchaseBlock)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    purchases.getOfferings { (_: Offerings?, _: Error?) in }
    purchases.getProducts([String]()) { (_: [StoreProduct]) in }

    let storeProduct: StoreProduct! = nil
    let pack: Package! = nil

    purchases.purchase(product: storeProduct) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(package: pack) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.syncPurchases { (_: CustomerInfo?, _: Error?) in }

#if os(iOS)
    purchases.presentCodeRedemptionSheet()
#endif

    // PurchasesDelegate
    let customerInfo: CustomerInfo? = nil
    purchases.delegate?.purchases?(purchases, receivedUpdated: customerInfo!)

    let purchaseBlock = { (_: @MainActor @Sendable (StoreTransaction?, CustomerInfo?, PublicError?, Bool) -> Void) in }
    purchases.delegate?.purchases?(purchases, readyForPromotedProduct: storeProduct, purchase: purchaseBlock)
}

private func checkIdentity(purchases: Purchases) {
    purchases.switchUser(to: "")
}

private func checkPurchasesSupportAPI(purchases: Purchases) {
    #if os(iOS)
    purchases.showManageSubscriptions { _ in }
    #endif
    #if os(iOS) || targetEnvironment(macCatalyst)
    _ = purchases.showPriceConsentIfNeeded
    _ = purchases.delegate?.shouldShowPriceConsent
    #endif
}

private func checkAsyncMethods(purchases: Purchases) async {
    let pack: Package! = nil
    let stp: StoreProduct! = nil

    do {
        let _: Offerings = try await purchases.offerings()

        let _: [StoreProduct] = await purchases.products([])
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp)
        let _: CustomerInfo = try await purchases.restorePurchases()
        let _: CustomerInfo = try await purchases.syncPurchases()

        for try await _: CustomerInfo in purchases.customerInfoStream {}

        #if os(iOS)
        try await purchases.showManageSubscriptions()
        let _: RefundRequestStatus = try await purchases.beginRefundRequest(forProduct: "")
        let _: RefundRequestStatus = try await purchases.beginRefundRequest(forEntitlement: "")
        let _: RefundRequestStatus = try await purchases.beginRefundRequestForActiveEntitlement()
        #endif
    } catch {}
}

func checkNonAsyncMethods(_ purchases: Purchases) {
    #if os(iOS)
    purchases.beginRefundRequest(forProduct: "") { (_: Result<RefundRequestStatus, PublicError>) in }
    purchases.beginRefundRequest(forEntitlement: "") { (_: Result<RefundRequestStatus, PublicError>) in }
    purchases.beginRefundRequestForActiveEntitlement { (_: Result<RefundRequestStatus, PublicError>) in }
    #endif
}

private func checkConfigure() -> Purchases! {
    Purchases.configureInCustomEntitlementsComputationMode(apiKey: "", appUserID: "")

    return nil
}
