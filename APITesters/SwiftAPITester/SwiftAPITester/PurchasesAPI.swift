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
    Purchases.configure(withAPIKey: "",
                        appUserID: nil,
                        observerMode: true,
                        userDefaults: UserDefaults(),
                        useStoreKit2IfAvailable: true)

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

    if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
        _ = Task.init {
            await checkAsyncMethods(purchases: purch)
        }
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

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    purchases.getCustomerInfo { (_: CustomerInfo?, _: Error?) in }
    purchases.getOfferings { (_: Offerings?, _: Error?) in }
    purchases.getProducts([String]()) { (_: [StoreProduct]) in }

    let storeProduct: StoreProduct! = nil
    let discount: StoreProductDiscount! = nil
    let pack: Package! = nil
    let offer: PromotionalOffer! = nil

    purchases.purchase(product: storeProduct) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(package: pack) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.syncPurchases { (_: CustomerInfo?, _: Error?) in }

    purchases.checkTrialOrIntroDiscountEligibility([String]()) { (_: [String: IntroEligibility]) in }
    purchases.getPromotionalOffer(
        forProductDiscount: discount,
        product: storeProduct
    ) { (_: PromotionalOffer?, _: Error?) in }

    purchases.purchase(product: storeProduct,
                       promotionalOffer: offer) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(package: pack,
                       promotionalOffer: offer) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.invalidateCustomerInfoCache()

#if os(iOS)
    purchases.presentCodeRedemptionSheet()
#endif

    // PurchasesDelegate
    let customerInfo: CustomerInfo? = nil
    purchases.delegate?.purchases?(purchases, receivedUpdated: customerInfo!)

    let defermentBlock = { (_: (StoreTransaction?, CustomerInfo?, Error?, Bool) -> Void) in }
    purchases.delegate?.purchases?(purchases, shouldPurchasePromoProduct: storeProduct, defermentBlock: defermentBlock)
}

private func checkIdentity(purchases: Purchases) {
    purchases.logOut { (_: CustomerInfo?, _: Error?) in }
    purchases.logIn("") { (_: CustomerInfo?, _: Bool, _: Error?) in }
}

private func checkPurchasesSupportAPI(purchases: Purchases) {
    #if os(iOS)
    purchases.showManageSubscriptions { _ in }
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
    purchases.setCleverTapID("")
    purchases.setMediaSource("")
    purchases.setCampaign("")
    purchases.setAdGroup("")
    purchases.setAd("")
    purchases.setKeyword("")
    purchases.setCreative("")
    purchases.collectDeviceIdentifiers()
}

private func checkAsyncMethods(purchases: Purchases) async {
    let pack: Package! = nil
    let stp: StoreProduct! = nil
    let discount: StoreProductDiscount! = nil
    let offer: PromotionalOffer! = nil

    do {
        let _: (CustomerInfo, Bool) = try await purchases.logIn("")
        let _: [String: IntroEligibility] = await purchases.checkTrialOrIntroDiscountEligibility([])
        let _: PromotionalOffer = try await purchases.getPromotionalOffer(
            forProductDiscount: discount,
            product: stp
        )
        let _: CustomerInfo = try await purchases.logOut()
        let _: Offerings = try await purchases.offerings()

        let _: [StoreProduct] = await purchases.products([])
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack,
                                                                                      promotionalOffer: offer)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp,
                                                                                      promotionalOffer: offer)
        let _: CustomerInfo = try await purchases.customerInfo()
        let _: CustomerInfo = try await purchases.restorePurchases()
        let _: CustomerInfo = try await purchases.syncPurchases()

        for try await _: CustomerInfo in purchases.customerInfoStream {}

        #if os(iOS)
        try await purchases.showManageSubscriptions()
        let _: RefundRequestStatus = try await purchases.beginRefundRequest(forProduct: "")
        let _: RefundRequestStatus = try await purchases.beginRefundRequest(forEntitlement: "")
        let _: RefundRequestStatus = try await purchases.beginRefundRequestForActiveEntitlement()

        let _: [PromotionalOffer] = await purchases.getEligiblePromotionalOffers(forProduct: stp)
        #endif
    } catch {}
}
