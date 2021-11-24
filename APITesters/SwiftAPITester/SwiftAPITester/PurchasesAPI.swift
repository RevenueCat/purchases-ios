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

var periodType: PeriodType!
var oType: PurchaseOwnershipType!
var logLevel: LogLevel!
func checkPurchasesEnums() {
    switch periodType! {
    case .normal,
         .intro,
         .trial:
        print(periodType!)
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
    purchases.getCustomerInfo { _, _ in }
    purchases.getOfferings { _, _ in }
    purchases.getProducts([String]()) { _ in }

    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        Task.init {
            let _: CustomerInfo = try await purchases.getCustomerInfo()
            let _: [SKProduct] = await purchases.getProducts([String]())
        }
    }

    let skp: SKProduct = SKProduct()
    let skpd: SKProductDiscount = SKProductDiscount()
    let skmd: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Package! = nil

    purchases.purchase(product: skp) { _, _, _, _  in }
    purchases.purchase(package: pack) { _, _, _, _  in }
    purchases.syncPurchases { _, _ in }

    let checkEligComplete: ([String: IntroEligibility]) -> Void = { _ in }
    purchases.checkTrialOrIntroductoryPriceEligibility([String](), completion: checkEligComplete)
    purchases.checkTrialOrIntroductoryPriceEligibility([String]()) { _ in }

    purchases.paymentDiscount(forProductDiscount: skpd, product: skp) { _, _ in }

    purchases.purchase(product: skp, discount: skmd) { _, _, _, _  in }
    purchases.purchase(package: pack, discount: skmd) { _, _, _, _  in }
    purchases.invalidateCustomerInfoCache()

#if os(iOS) || targetEnvironment(macCatalyst)
    let beginRefundRequestCompletion: (RefundRequestStatus, Error?) -> Void = { _, _ in }
    purchases.beginRefundRequest(for: "asdf", completion: beginRefundRequestCompletion)
    purchases.beginRefundRequest(for: "asdf") { _, _ in }
#endif

#if os(iOS)
    purchases.presentCodeRedemptionSheet()
#endif

    // PurchasesDelegate
    let customerInfo: CustomerInfo? = nil
    purchases.delegate?.purchases?(purchases, receivedUpdated: customerInfo!)

    let defermentBlock: DeferredPromotionalPurchaseBlock = { _ in }
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp, defermentBlock: defermentBlock)
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: skp) { _ in }
}

private func checkIdentity(purchases: Purchases) {
    // should have deprecation warning 'createAlias' is deprecated: Use logIn instead.
    purchases.createAlias("") { _, _ in }

    // should have deprecation warning 'identify' is deprecated: Use logIn instead.
    purchases.identify("") { _, _ in }

    // should have deprecation warning 'reset' is deprecated: Use logOut instead.
    purchases.reset { _, _ in }

    purchases.logOut { _, _ in }

    let loginComplete: (CustomerInfo?, Bool, Error?) -> Void = { _, _, _ in }
    purchases.logIn("", completion: loginComplete)
    purchases.logIn("") { _, _, _ in }
    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        Task.init {
            let (_, _): (CustomerInfo, Bool) = try await purchases.logIn("")
            let _: CustomerInfo = try await purchases.logOut()
        }
    }
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
    purchases.collectDeviceIdentifiers()
}
