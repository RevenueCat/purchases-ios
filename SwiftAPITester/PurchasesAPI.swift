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
import RevenueCat
import StoreKit

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

    print(finishTransactions, delegate!, appUserID, isAnonymous)

    checkStaticMethods()
    checkIdentity(purchases: purch)
    checkPurchasesSubscriberAttributesAPI(purchases: purch)
    checkPurchasesPurchasingAPI(purchases: purch)
}

var type: PeriodType!
var oType: PurchaseOwnershipType!
var logLevel: LogLevel!
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
//    let errDom = errorDomain
//    let backendErrDom = backendErrCode
    let finKey = ErrorDetails.finishableKey
    let errCodeKey = ErrorDetails.readableErrorCodeKey

//    print(errDom, backendErrDom, finKey, errCodeKey)
    print(finKey, errCodeKey)
}

private func checkStaticMethods() {
    let logHandler: (LogLevel, String) -> Void = { _, _ in }
    Purchases.logHandler = logHandler

    let canI: Bool = Purchases.canMakePayments()
    let version = Purchases.frameworkVersion

    // both should have deprecation warning
    Purchases.addAttributionData([String: Any](), from: AttributionNetwork.adjust, forNetworkUserId: "")
    Purchases.addAttributionData([String: Any](), from: AttributionNetwork.adjust, forNetworkUserId: nil)

    let automaticAppleSearchAdsAttributionCollection: Bool = Purchases.automaticAppleSearchAdsAttributionCollection
    // should have deprecation warning 'debugLogsEnabled' is deprecated: use logLevel instead
    let debugLogsEnabled: Bool = Purchases.debugLogsEnabled
    let logLevel: LogLevel = Purchases.logLevel
    let proxyUrl: URL? = Purchases.proxyURL
    let forceUniversalAppStore: Bool = Purchases.forceUniversalAppStore
    let simulatesAskToBuyInSandbox: Bool = Purchases.simulatesAskToBuyInSandbox
    let sharedPurchases: Purchases = Purchases.shared
    let isPurchasesConfigured: Bool = Purchases.isConfigured

    print(canI, version, automaticAppleSearchAdsAttributionCollection, debugLogsEnabled, logLevel, proxyUrl!,
          forceUniversalAppStore, simulatesAskToBuyInSandbox, sharedPurchases, isPurchasesConfigured)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    let piComplete: ReceivePurchaserInfoBlock = { _, _ in }
    purchases.purchaserInfo(piComplete)
    purchases.purchaserInfo { _, _ in }

    let offeringsComplete: ReceiveOfferingsBlock = { _, _ in }
    purchases.offerings(offeringsComplete)
    purchases.offerings { _, _ in }

    let productsComplete: ReceiveProductsBlock = { _ in }
    purchases.products([String](), productsComplete)
    purchases.products([String]()) { _ in }

    let skp: SKProduct = SKProduct()
    let skpd: SKProductDiscount = SKProductDiscount()
    let skmd: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Package! = nil

    let purchaseProductComplete: PurchaseCompletedBlock = { _, _, _, _  in }
    purchases.purchase(product: skp, purchaseProductComplete)
    purchases.purchase(product: skp) { _, _, _, _  in }
    purchases.purchase(package: pack, purchaseProductComplete)
    purchases.purchase(package: pack) { _, _, _, _  in }

    purchases.restoreTransactions(piComplete)
    purchases.syncPurchases(piComplete)

    let checkEligComplete: ([String: IntroEligibility]) -> Void = { _ in }
    purchases.checkTrialOrIntroductoryPriceEligibility([String](), completion: checkEligComplete)
    purchases.checkTrialOrIntroductoryPriceEligibility([String]()) { _ in }

    let discountComplete: PaymentDiscountBlock = { _, _ in }

    purchases.paymentDiscount(forProductDiscount: skpd, product: skp, completion: discountComplete)
    purchases.paymentDiscount(forProductDiscount: skpd, product: skp) { _, _ in }

    purchases.purchase(product: skp, discount: skmd, completion: purchaseProductComplete)
    purchases.purchase(product: skp, discount: skmd) { _, _, _, _  in }
    purchases.purchase(package: pack, discount: skmd, completion: purchaseProductComplete)
    purchases.purchase(package: pack, discount: skmd) { _, _, _, _  in }
    purchases.invalidatePurchaserInfoCache()

    // PurchasesDelegate
    let purchaserInfo: PurchaserInfo? = nil
    purchases.delegate?.purchases?(purchases, didReceiveUpdated: purchaserInfo!)

    let defermentBlock: DeferredPromotionalPurchaseBlock = { _ in }
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp, defermentBlock: defermentBlock)
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp) { _ in }
}

private func checkIdentity(purchases: Purchases) {
    let piComplete: ReceivePurchaserInfoBlock = { _, _ in }

    // should have deprecation warning 'createAlias' is deprecated: Use logIn instead.
    purchases.createAlias("", piComplete)
    purchases.createAlias("") { _, _ in }

    // should have deprecation warning 'identify' is deprecated: Use logIn instead.
    purchases.identify("", piComplete)
    purchases.identify("") { _, _ in }

    // should have deprecation warning 'reset' is deprecated: Use logOut instead.
    purchases.reset(piComplete)
    purchases.reset { _, _ in }

    purchases.logOut(piComplete)

    let loginComplete: (PurchaserInfo?, Bool, Error?) -> Void = { _, _, _ in }
    purchases.logIn("", loginComplete)
    purchases.logIn("") { _, _, _ in }
}

private func checkPurchasesSubscriberAttributesAPI(purchases: Purchases) {
    purchases.setAttributes([String: String]())
    purchases.setEmail("")
    purchases.setPhoneNumber("")
    purchases.setDisplayName("")
    purchases.setPushToken("".data(using: String.Encoding.utf8)!)
    purchases.setAdjustID("")
    purchases.setAppsflyerID("")
    purchases.setFBAnonymousID("")
    purchases.setMparticleID("")
    purchases.setOnesignalID("")
    purchases.setMediaSource("")
    purchases.setCampaign("")
    purchases.setAdGroup("")
    purchases.setAd("")
    purchases.setKeyword("")
    purchases.setCreative("")
//    purchases.collectDeviceIdentifiers()
}
