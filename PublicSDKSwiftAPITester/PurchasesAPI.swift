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

    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true, userDefaults: nil)
    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true, userDefaults: UserDefaults())

    // static methods
    let logHandler: (Purchases.LogLevel, String) -> Void = { _, _ in }
    Purchases.setLogHandler(logHandler)

    let canI: Bool = Purchases.canMakePayments()
    let version = Purchases.frameworkVersion

    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust, forNetworkUserId: "")
    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust, forNetworkUserId: nil)

    let automaticAppleSearchAdsAttributionCollection: Bool = Purchases.automaticAppleSearchAdsAttributionCollection
    let debugLogsEnabled: Bool = Purchases.debugLogsEnabled
    let logLevel = Purchases.logLevel
    let proxyUrl: URL? = Purchases.proxyURL
    let forceUniversalAppStore: Bool = Purchases.forceUniversalAppStore
    let simulatesAskToBuyInSandbox: Bool = Purchases.simulatesAskToBuyInSandbox
    let sharedPurchases: Purchases = Purchases.shared
    let isConfigured: Bool = Purchases.isConfigured
    let finishTransactions: Bool = purch.finishTransactions
    let delegate: PurchasesDelegate? = purch.delegate
    let appUserID: String = purch.appUserID
    let isAnonymous: Bool = purch.isAnonymous

    print(canI, version, automaticAppleSearchAdsAttributionCollection, debugLogsEnabled, logLevel, proxyUrl!,
          forceUniversalAppStore, simulatesAskToBuyInSandbox, sharedPurchases, isConfigured, finishTransactions,
          delegate!, appUserID, isAnonymous)

    checkPurchasesSubscriberAttributesAPI(purchases: purch)
    checkPurchasesPurchasingAPI(purchases: purch)

    let piComplete: Purchases.ReceivePurchaserInfoBlock = { _, _ in }
    // identity
    purch.createAlias("", piComplete)
    purch.identify("", piComplete)
    purch.reset(piComplete)
    purch.logOut(piComplete)

    let loginComplete: (Purchases.PurchaserInfo?, Bool, Error?) -> Void = { _, _, _ in }
    purch.logIn("", loginComplete)
}

func checkPurchasesEnums() {
    var type = Purchases.PeriodType.normal
    type = Purchases.PeriodType.intro
    type = Purchases.PeriodType.trial

    var oType: RCPurchaseOwnershipType = RCPurchaseOwnershipType.purchased
    oType = RCPurchaseOwnershipType.familyShared
    oType = RCPurchaseOwnershipType.unknown

    var logLevel: Purchases.LogLevel = Purchases.LogLevel.info
    logLevel = Purchases.LogLevel.warn
    logLevel = Purchases.LogLevel.debug
    logLevel = Purchases.LogLevel.error

    print(type, oType, logLevel)
}

func checkConstants() {
    // were these never available from swift?
//    let versionNum: Double = PurchasesVersionNumber
//    let versionString: String = PurchasesVersionString

//    print(versionNum)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    let piComplete: Purchases.ReceivePurchaserInfoBlock = { _, _ in }
    purchases.purchaserInfo(piComplete)

    let offeringsComplete: Purchases.ReceiveOfferingsBlock = { _, _ in }
    purchases.offerings(offeringsComplete)

    let productsComplete: Purchases.ReceiveProductsBlock = { _ in }
    purchases.products([String](), productsComplete)

    let skp: SKProduct = SKProduct()
    let skpd: SKProductDiscount = SKProductDiscount()
    let skmd: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Purchases.Package = Purchases.Package()

    let purchaseProductComplete: Purchases.PurchaseCompletedBlock = { _, _, _, _  in }
    purchases.purchaseProduct(skp, purchaseProductComplete)
    purchases.purchasePackage(pack, purchaseProductComplete)

    purchases.restoreTransactions(piComplete)
    purchases.syncPurchases(piComplete)

    let checkEligComplete: ([String: RCIntroEligibility]) -> Void = { _ in }
    purchases.checkTrialOrIntroductoryPriceEligibility([String](), completionBlock: checkEligComplete)

    let discountComplete: Purchases.PaymentDiscountBlock = { _, _ in }
    purchases.paymentDiscount(for: skpd, product: skp, completion: discountComplete)
    purchases.purchaseProduct(skp, discount: skmd, purchaseProductComplete)
    purchases.purchasePackage(pack, discount: skmd, purchaseProductComplete)
    purchases.invalidatePurchaserInfoCache()

    // PurchasesDelegate
    let purchaserInfo: Purchases.PurchaserInfo? = nil
    purchases.delegate?.purchases?(purchases, didReceiveUpdated: purchaserInfo!)

    let defermentBlock: RCDeferredPromotionalPurchaseBlock = { _ in }
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp, defermentBlock: defermentBlock)
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
