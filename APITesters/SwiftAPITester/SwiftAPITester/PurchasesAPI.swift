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
    checkPurchasesSupportAPI(purchases: purch)
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
    case .info,
         .warn,
         .debug,
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

// swiftlint:disable:next function_body_length
private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    purchases.getCustomerInfo { _, _ in }
    purchases.getOfferings { _, _ in }
    purchases.getProducts([String]()) { _ in }

    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        Task.init {
            let _: CustomerInfo = try await purchases.customerInfo()
            let _: [SKProduct] = await purchases.products([String]())
            let _: Offerings = try await purchases.offerings()
        }
    }

    let skp: SKProduct = SKProduct()
    let productDiscount: SKProductDiscount = SKProductDiscount()
    let paymentDiscount: SKPaymentDiscount = SKPaymentDiscount()
    let pack: Package! = nil

    purchases.purchase(product: skp) { _, _, _, _  in }
    purchases.purchase(package: pack) { _, _, _, _  in }
    purchases.syncPurchases { _, _ in }

    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        Task.init {
            let (_, _, _): (SKPaymentTransaction, CustomerInfo, Bool) = try await purchases.purchase(product: skp)
            let (_, _, _): (SKPaymentTransaction, CustomerInfo, Bool) = try await purchases.purchase(package: pack)
            let _: CustomerInfo = try await purchases.syncPurchases()
            let _: CustomerInfo = try await purchases.restoreTransactions()
        }
    }

    let checkEligComplete: ([String: IntroEligibility]) -> Void = { _ in }
    purchases.checkTrialOrIntroductoryPriceEligibility([String](), completion: checkEligComplete)
    purchases.checkTrialOrIntroductoryPriceEligibility([String]()) { _ in }

    purchases.paymentDiscount(forProductDiscount: productDiscount, product: skp) { _, _ in }

    purchases.purchase(product: skp, discount: paymentDiscount) { _, _, _, _  in }
    purchases.purchase(package: pack, discount: paymentDiscount) { _, _, _, _  in }
    purchases.invalidateCustomerInfoCache()

    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        Task.init {
            let (_, _, _): (SKPaymentTransaction, CustomerInfo, Bool) =
            try await purchases.purchase(product: skp, discount: paymentDiscount)
            let (_, _, _): (SKPaymentTransaction, CustomerInfo, Bool) =
            try await purchases.purchase(package: pack, discount: paymentDiscount)
            let _: [String: IntroEligibility] = await purchases.checkTrialOrIntroductoryPriceEligibility([String]())
            let _: SKPaymentDiscount = try await purchases.paymentDiscount(forProductDiscount: productDiscount,
                                                                           product: skp)
        }
    }

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

private func checkPurchasesSupportAPI(purchases: Purchases) {
    purchases.showManageSubscriptions { _ in }
    #if os(iOS)
    purchases.beginRefundRequest(for: "") { _, _ in }
    if #available(iOS 15.0, macOS 12.0, *) {
        Task.init {
            try await purchases.showManageSubscriptions()
            let _: RefundRequestStatus = try await purchases.beginRefundRequest(for: "")
        }
    }
    #endif
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
