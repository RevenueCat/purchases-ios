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
import StoreKit

func checkPurchasesAPI() {

    // initializers
    let purch = Purchases.configure(withAPIKey: "")
    Purchases.configure(withAPIKey: "", appUserID: nil)
    Purchases.configure(withAPIKey: "", appUserID: "")

    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: false)

    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true, userDefaults: nil)
    Purchases.configure(withAPIKey: "", appUserID: "", observerMode: true, userDefaults: UserDefaults())

    // static methods
    let logHandler: (LogLevel, String) -> Void = { _, _ in }
    Purchases.logHandler = logHandler

    let canI: Bool = Purchases.canMakePayments()
    let version = Purchases.frameworkVersion
    Purchases.addAttributionData([:], from: .adjust, forNetworkUserId: "")
    Purchases.addAttributionData([:], from: .adjust, forNetworkUserId: nil)

    let automaticAppleSearchAdsAttributionCollection: Bool = Purchases.automaticAppleSearchAdsAttributionCollection
    let debugLogsEnabled: Bool = Purchases.debugLogsEnabled
    let logLevel: LogLevel = Purchases.logLevel
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

    let piComplete: ReceivePurchaserInfoBlock = { _, _ in }
    // identity
    purch.createAlias("", completionBlock: piComplete)
    purch.identify("", completionBlock: piComplete)
    purch.reset(completionBlock: piComplete)
    purch.logOut(completionBlock: piComplete)

    let loginComplete: (PurchaserInfo?, Bool, Error?) -> Void = { _, _, _ in }
    purch.logIn(appUserID: "", completionBlock: loginComplete)
}

func checkPurchasesEnums() {
    var type: PeriodType = PeriodType.normal
    type = PeriodType.intro
    type = PeriodType.trial

    var oType: PurchaseOwnershipType = PurchaseOwnershipType.purchased
    oType = PurchaseOwnershipType.familyShared
    oType = PurchaseOwnershipType.unknown

    var logLevel: LogLevel = LogLevel.info
    logLevel = LogLevel.warn
    logLevel = LogLevel.debug
    logLevel = LogLevel.error

    print(type, oType, logLevel)
}

func checkConstants() {
    // were these never available from swift?
//    let versionNum: Double = PurchasesVersionNumber
//    let versionString: String = PurchasesVersionString

//    print(versionNum)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    let piComplete: ReceivePurchaserInfoBlock = { _, _ in }
    purchases.purchaserInfo(completionBlock: piComplete)

    let offeringsComplete: ReceiveOfferingsBlock = { _, _ in }
    purchases.offerings(completionBlock: offeringsComplete)

    let productsComplete: ReceiveProductsBlock = { _ in }
    purchases.products(identifiers: [String](), completionBlock: productsComplete)

    let skp: SKProduct = SKProduct()
    let skpd: SKProductDiscount = SKProductDiscount()
    let skmd: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Package = Package(identifier: "", packageType: .custom, product: SKProduct(), offeringIdentifier: "")

    let purchaseProductComplete: PurchaseCompletedBlock = { _, _, _, _  in }
    purchases.purchase(product: skp, completion: purchaseProductComplete)
    purchases.purchase(package: pack, completion: purchaseProductComplete)

    purchases.restoreTransactions(completionBlock: piComplete)
    purchases.syncPurchases(completionBlock: piComplete)

    let checkEligComplete: ([String: IntroEligibility]) -> Void = { _ in }
    purchases.checkTrialOrIntroductoryPriceEligibility([], completionBlock: checkEligComplete)

    let discountComplete: PaymentDiscountBlock = { _, _ in }
    purchases.paymentDiscount(forProductDiscount: skpd, product: skp, completion: discountComplete)
    purchases.purchase(product: skp, discount: skmd, completion: purchaseProductComplete)
    purchases.purchase(package: pack, discount: skmd, completion: purchaseProductComplete)
    purchases.invalidatePurchaserInfoCache()

    // PurchasesDelegate
    let purchaserInfo: PurchaserInfo? = nil
    purchases.delegate?.purchases?(purchases, didReceiveUpdated: purchaserInfo!)

    let defermentBlock: DeferredPromotionalPurchaseBlock = { _ in }
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp, defermentBlock: defermentBlock)
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
