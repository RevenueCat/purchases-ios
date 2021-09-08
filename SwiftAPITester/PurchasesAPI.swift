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
import Purchases

func checkPurchasesAPI() {
    // initializers
    let purch = Purchases.configure(withAPIKey: "")
    Purchases.configure(withAPIKey: "", appUserID: nil)
    Purchases.configure(withAPIKey: "", appUserID: "")

    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: false)
    Purchases.configure(withAPIKey: "", appUserID: nil, observerMode: true)

    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true, userDefaults: nil)
    Purchases.configure(withAPIKey: "", appUserID: nil, observerMode: true, userDefaults: nil)
    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true, userDefaults: UserDefaults())
    Purchases.configure(withAPIKey: "", appUserID: nil, observerMode: true, userDefaults: UserDefaults())

    let finishTransactions: Bool = purch.finishTransactions
    let delegate: PurchasesDelegate? = purch.delegate
    let appUserID: String = purch.appUserID
    let isAnonymous: Bool = purch.isAnonymous

    print(purch.description, finishTransactions, delegate!, appUserID, isAnonymous)

    checkStaticMethods()
    checkIdentity(purchases: purch)
    checkPurchasesSubscriberAttributesAPI(purchases: purch)
    checkPurchasesPurchasingAPI(purchases: purch)

}

var type: Purchases.PeriodType!
var oType: RCPurchaseOwnershipType!
var logLevel: Purchases.LogLevel!
func checkPurchasesEnums() {
    switch type! {
    case .normal,
         .intro,
         .trial:
        print(type!)
    }

    switch oType! {
    case .purchased,
         .familyShared,
         .unknown:
        print(oType!)
    }

    switch logLevel! {
    case .info,
         .warn,
         .debug,
         .error:
        print(logLevel!)
    }
}

func checkPurchasesConstants() {
    let errDom = Purchases.ErrorDomain
    let backendErrDom = Purchases.RevenueCatBackendErrorDomain
    let finKey = Purchases.FinishableKey
    let errCodeKey = Purchases.ReadableErrorCodeKey

    print(errDom, backendErrDom, finKey, errCodeKey)
}

private func checkStaticMethods() {
    let logHandler: (Purchases.LogLevel, String) -> Void = { _, _ in }
    Purchases.setLogHandler(logHandler)
    Purchases.setLogHandler { _, _ in }

    let canI: Bool = Purchases.canMakePayments()
    let version = Purchases.frameworkVersion

    // both should have deprecation warning
    // 'addAttributionData(_:from:forNetworkUserId:)' is deprecated: Use the set<NetworkId> functions instead.
    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust, forNetworkUserId: "")
    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust, forNetworkUserId: nil)

    let automaticAppleSearchAdsAttributionCollection: Bool = Purchases.automaticAppleSearchAdsAttributionCollection
    // should have deprecation warning 'debugLogsEnabled' is deprecated: use logLevel instead
    let debugLogsEnabled: Bool = Purchases.debugLogsEnabled
    let logLevel: Purchases.LogLevel = Purchases.logLevel
    let proxyUrl: URL? = Purchases.proxyURL
    let forceUniversalAppStore: Bool = Purchases.forceUniversalAppStore
    let simulatesAskToBuyInSandbox: Bool = Purchases.simulatesAskToBuyInSandbox
    let sharedPurchases: Purchases = Purchases.shared
    let isConfigured: Bool = Purchases.isConfigured

    print(canI, version, automaticAppleSearchAdsAttributionCollection, debugLogsEnabled, logLevel, proxyUrl!,
          forceUniversalAppStore, simulatesAskToBuyInSandbox, sharedPurchases, isConfigured)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    let piComplete: Purchases.ReceivePurchaserInfoBlock = { _, _ in }
    purchases.purchaserInfo(piComplete)
    purchases.purchaserInfo { _, _ in }

    let offeringsComplete: Purchases.ReceiveOfferingsBlock = { _, _ in }
    purchases.offerings(offeringsComplete)
    purchases.offerings { _, _ in }

    let productsComplete: Purchases.ReceiveProductsBlock = { _ in }
    purchases.products([String](), productsComplete)
    purchases.products([String]()) { _ in }

    let skp: SKProduct = SKProduct()
    let skpd: SKProductDiscount = SKProductDiscount()
    let skmd: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Purchases.Package = Purchases.Package()

    let purchaseProductComplete: Purchases.PurchaseCompletedBlock = { _, _, _, _  in }
    purchases.purchaseProduct(skp, purchaseProductComplete)
    purchases.purchaseProduct(skp) { _, _, _, _  in }
    purchases.purchasePackage(pack, purchaseProductComplete)
    purchases.purchasePackage(pack) { _, _, _, _  in }

    purchases.restoreTransactions(piComplete)
    purchases.syncPurchases(piComplete)

    let checkEligComplete: ([String: RCIntroEligibility]) -> Void = { _ in }
    purchases.checkTrialOrIntroductoryPriceEligibility([String](), completionBlock: checkEligComplete)
    purchases.checkTrialOrIntroductoryPriceEligibility([String]()) { _ in }

    let discountComplete: Purchases.PaymentDiscountBlock = { _, _ in }

    purchases.paymentDiscount(for: skpd, product: skp, completion: discountComplete)
    purchases.paymentDiscount(for: skpd, product: skp) { _, _ in }

    purchases.purchaseProduct(skp, discount: skmd, purchaseProductComplete)
    purchases.purchaseProduct(skp, discount: skmd) { _, _, _, _  in }
    purchases.purchasePackage(pack, discount: skmd, purchaseProductComplete)
    purchases.purchasePackage(pack, discount: skmd) { _, _, _, _  in }
    purchases.invalidatePurchaserInfoCache()

    // PurchasesDelegate
    let purchaserInfo: Purchases.PurchaserInfo? = nil
    purchases.delegate?.purchases?(purchases, didReceiveUpdated: purchaserInfo!)

    let defermentBlock: RCDeferredPromotionalPurchaseBlock = { _ in }
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp, defermentBlock: defermentBlock)
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp) { _ in }
}

private func checkIdentity(purchases: Purchases) {
    let piComplete: Purchases.ReceivePurchaserInfoBlock = { _, _ in }

    // should have deprecation warning 'createAlias' is deprecated: Use logIn instead.
    purchases.createAlias("", piComplete)
    purchases.createAlias("")

    // should have deprecation warning 'identify' is deprecated: Use logIn instead.
    purchases.identify("", piComplete)
    purchases.identify("") { _, _ in }

    // should have deprecation warning 'reset' is deprecated: Use logOut instead.
    purchases.reset(piComplete)
    purchases.reset { _, _ in }

    purchases.logOut(piComplete)

    let loginComplete: (Purchases.PurchaserInfo?, Bool, Error?) -> Void = { _, _, _ in }
    purchases.logIn("", loginComplete)
    purchases.logIn("") { _, _, _ in }
}

private func checkPurchasesSubscriberAttributesAPI(purchases: Purchases) {
    purchases.setAttributes([String: String]())
    purchases.setEmail("")
    purchases.setEmail(nil)
    purchases.setPhoneNumber("")
    purchases.setPhoneNumber(nil)
    purchases.setDisplayName("")
    purchases.setDisplayName(nil)
    purchases.setPushToken("".data(using: String.Encoding.utf8))
    purchases.setPushToken(nil)
    purchases.setAdjustID("")
    purchases.setAdjustID(nil)
    purchases.setAppsflyerID("")
    purchases.setAppsflyerID(nil)
    purchases.setFBAnonymousID("")
    purchases.setFBAnonymousID(nil)
    purchases.setMparticleID("")
    purchases.setMparticleID(nil)
    purchases.setOnesignalID("")
    purchases.setOnesignalID(nil)
    purchases.setMediaSource("")
    purchases.setMediaSource(nil)
    purchases.setCampaign("")
    purchases.setCampaign(nil)
    purchases.setAdGroup("")
    purchases.setAdGroup(nil)
    purchases.setAd("")
    purchases.setAd(nil)
    purchases.setKeyword("")
    purchases.setKeyword(nil)
    purchases.setCreative("")
    purchases.setCreative(nil)
    purchases.collectDeviceIdentifiers()
}
