//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  File.swift
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
    let version = Purchases.frameworkVersion()
    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust)
    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust, forNetworkUserId: "")
    Purchases.addAttributionData([AnyHashable: Any](), from: RCAttributionNetwork.adjust, forNetworkUserId: nil)

    let automaticAppleSearchAdsAttributionCollection: Bool = Purchases.automaticAppleSearchAdsAttributionCollection
    let debugLogsEnabled: Bool = Purchases.debugLogsEnabled
    let logLevel: Purchases.LogLevel = Purchases.logLevel
    let proxyUrl: URL? = Purchases.proxyURL
    let forceUniversalAppStore: Bool = Purchases.forceUniversalAppStore
    let simulatesAskToBuyInSandbox: Bool = Purchases.simulatesAskToBuyInSandbox
    let sharedPurchases: Purchases = Purchases.shared
    let isConfigured: Bool = Purchases.isConfigured
    let finishTransactions: Bool = p.finishTransactions
    let delegate: PurchasesDelegate? = p.delegate
    let appUserID: String = p.appUserID
    let isAnonymous: Bool = p.isAnonymous

    print(canI, version, automaticAppleSearchAdsAttributionCollection, debugLogsEnabled, logLevel, proxyUrl!,
          forceUniversalAppStore, simulatesAskToBuyInSandbox, sharedPurchases, isConfigured, finishTransactions,
          delegate!, appUserID, isAnonymous)

    checkPurchasesSubscriberAttributesAPI()
    checkPurchasesPurchasingAPI()

    // identity
    purch.createAlias("", piComplete)
    purch.identify("", piComplete)
    purch.reset(piComplete)
    purch.logOut(piComplete)

    let loginComplete: (Purchases.PurchaserInfo?, Bool, Error?) -> Void = { _, _, _ in }
    purch.logIn("", loginComplete)

    // PurchasesDelegate
    let purchaserInfo: Purchases.PurchaserInfo? = nil
    purch.delegate?.purchases?(p, didReceiveUpdated: purchaserInfo!)

    let defermentBlock: RCDeferredPromotionalPurchaseBlock = { _ in }
    purch.delegate?.purchases?(p, shouldPurchasePromoProduct: skp, defermentBlock: defermentBlock)

}

func checkPurchasesEnums() {
    var type: Purchases.PeriodType = Purchases.PeriodType.normal
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
    // TODO fix
//    let vn: Double = PurchasesVersionNumber
//    let vs: String = Purchases.PurchasesVersionString

    log(vn)
}

private func checkPurchasesPurchasingAPI() {
    let piComplete: Purchases.ReceivePurchaserInfoBlock = { _, _ in }
    purch.purchaserInfo(piComplete)

    let offeringsComplete: Purchases.ReceiveOfferingsBlock = { _, _ in }
    purch.offerings(offeringsComplete)

    let productsComplete: Purchases.ReceiveProductsBlock = { _ in }
    purch.products([String](), productsComplete)

    let skp: SKProduct = SKProduct()
    let skpd: SKProductDiscount = SKProductDiscount()
    let skmd: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Purchases.Package = Purchases.Package()

    let purchaseProductComplete: Purchases.PurchaseCompletedBlock = { _, _, _, _  in }
    purch.purchaseProduct(skp, purchaseProductComplete)
    purch.purchasePackage(pack, purchaseProductComplete)

    purch.restoreTransactions(piComplete)
    purch.syncPurchases(piComplete)

    let checkEligComplete: ([String: RCIntroEligibility]) -> Void = { _ in }
    purch.checkTrialOrIntroductoryPriceEligibility([String](), completionBlock: checkEligComplete)

    let discountComplete: Purchases.PaymentDiscountBlock = { _, _ in }
    purch.paymentDiscount(for: skpd, product: skp, completion: discountComplete)
    purch.purchaseProduct(skp, discount: skmd, purchaseProductComplete)
    purch.purchasePackage(pack, discount: skmd, purchaseProductComplete)
    purch.invalidatePurchaserInfoCache()
}

private func checkPurchasesSubscriberAttributesAPI() {
    purch.setAttributes([String: String]())
    purch.setEmail("")
    purch.setEmail(nil)
    purch.setPhoneNumber("")
    purch.setPhoneNumber(nil)
    purch.setDisplayName("")
    purch.setDisplayName(nil)
    purch.setPushToken("".data(using: String.Encoding.utf8))
    purch.setPushToken(nil)
    purch.setAdjustID("")
    purch.setAdjustID(nil)
    purch.setAppsflyerID("")
    purch.setAppsflyerID(nil)
    purch.setFBAnonymousID("")
    purch.setFBAnonymousID(nil)
    purch.setMparticleID("")
    purch.setMparticleID(nil)
    purch.setOnesignalID("")
    purch.setOnesignalID(nil)
    purch.setMediaSource("")
    purch.setMediaSource(nil)
    purch.setCampaign("")
    purch.setCampaign(nil)
    purch.setAdGroup("")
    purch.setAdGroup(nil)
    purch.setAd("")
    purch.setAd(nil)
    purch.setKeyword("")
    purch.setKeyword(nil)
    purch.setCreative("")
    purch.setCreative(nil)
    purch.collectDeviceIdentifiers()
}
