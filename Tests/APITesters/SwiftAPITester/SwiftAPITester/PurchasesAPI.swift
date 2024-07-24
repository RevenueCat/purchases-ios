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
    let purch = checkConfigure()!

    // initializers
    let purchasesAreCompletedBy: PurchasesAreCompletedBy = purch.purchasesAreCompletedBy
    let delegate: PurchasesDelegate? = purch.delegate
    let appUserID: String = purch.appUserID
    let isAnonymous: Bool = purch.isAnonymous

    print(purchasesAreCompletedBy, delegate!, appUserID, isAnonymous)

    checkStaticMethods()
    checkIdentity(purchases: purch)
    checkPurchasesPurchasingAPI(purchases: purch)
    checkPurchasesSupportAPI(purchases: purch)

    let _: Attribution = purch.attribution

    _ = Task<Void, Never> {
        await checkAsyncMethods(purchases: purch)
    }

    checkNonAsyncMethods(purch)
}

var periodType: PeriodType!
var oType: PurchaseOwnershipType!
var logLevel: LogLevel!
var storeMessageType: StoreMessageType!
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

    switch storeMessageType! {
    case .billingIssue,
         .priceIncreaseConsent,
         .generic:
        print(storeMessageType!)
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

    // swiftlint:disable:next line_length redundant_void_return
    let purchaseCompletedBlock: PurchaseCompletedBlock = { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) -> Void in }

    let startPurchaseBlock: StartPurchaseBlock = { (_: PurchaseCompletedBlock) in }

    print(purchaseResultData,
          purchaseCompletedBlock,
          startPurchaseBlock)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    purchases.getCustomerInfo { (_: CustomerInfo?, _: Error?) in }
    purchases.getCustomerInfo(fetchPolicy: .default) { (_: CustomerInfo?, _: Error?) in }
    let _: CustomerInfo? = purchases.cachedCustomerInfo

    purchases.getOfferings { (_: Offerings?, _: Error?) in }
    let _: Offerings? = purchases.cachedOfferings

    purchases.syncAttributesAndOfferingsIfNeeded { (_: Offerings?, _: Error?) in }

    purchases.getProducts([String]()) { (_: [StoreProduct]) in }

    let storeProduct: StoreProduct! = nil
    let discount: StoreProductDiscount! = nil
    let pack: Package! = nil
    let offer: PromotionalOffer! = nil

    purchases.purchase(product: storeProduct) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(package: pack) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.restorePurchases { (_: CustomerInfo?, _: Error?) in }
    purchases.syncPurchases { (_: CustomerInfo?, _: Error?) in }

    purchases.checkTrialOrIntroDiscountEligibility(product: storeProduct) { (_: IntroEligibilityStatus) in }
    purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: [String]()) { (_: [String: IntroEligibility]) in
    }

    purchases.getPromotionalOffer(
        forProductDiscount: discount,
        product: storeProduct
    ) { (_: PromotionalOffer?, _: Error?) in }
    purchases.purchase(product: storeProduct,
                       promotionalOffer: offer) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(package: pack,
                       promotionalOffer: offer) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }

    purchases.invalidateCustomerInfoCache()

#if os(iOS) || VISION_OS
    if #available(iOS 14.0, *) {
        purchases.presentCodeRedemptionSheet()
    }
#endif

    // PurchasesDelegate
    let customerInfo: CustomerInfo? = nil
    purchases.delegate?.purchases?(purchases, receivedUpdated: customerInfo!)

    let purchaseBlock = { (_: @MainActor @Sendable (StoreTransaction?, CustomerInfo?, PublicError?, Bool) -> Void) in }
    purchases.delegate?.purchases?(purchases, readyForPromotedProduct: storeProduct, purchase: purchaseBlock)
}

private func checkIdentity(purchases: Purchases) {
    purchases.logOut { (_: CustomerInfo?, _: Error?) in }
}

private func checkPurchasesSupportAPI(purchases: Purchases) {
    #if os(iOS) || VISION_OS
    if #available(iOS 13.0, macOS 10.15, *) {
        purchases.showManageSubscriptions { _ in }
    }
    #endif
    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    if #available(iOS 13.4, macCatalyst 13.4, *) {
        _ = purchases.showPriceConsentIfNeeded
        _ = purchases.delegate?.shouldShowPriceConsent
    }
    #endif
    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    if #available(iOS 16.0, *) {
        Task {
            await purchases.showStoreMessages()
            await purchases.showStoreMessages(for: [StoreMessageType.billingIssue])
        }
    }
    #endif
}

@available(*, deprecated) // Ignore deprecation warnings
private func checkPurchasesSubscriberAttributesAPI(purchases: Purchases) {
    purchases.setAttributes([String: String]())
    purchases.setEmail("")
    purchases.setPhoneNumber("")
    purchases.setDisplayName("")
    purchases.setPushToken("".data(using: String.Encoding.utf8)!)
    purchases.setPushToken(nil)
    purchases.setPushTokenString("")
    purchases.setPushTokenString(nil)
    purchases.setAdjustID("")
    purchases.setAppsflyerID("")
    purchases.setFBAnonymousID("")
    purchases.setMparticleID("")
    purchases.setOnesignalID("")
    purchases.setCleverTapID("")
    purchases.setMixpanelDistinctID("")
    purchases.setFirebaseAppInstanceID("")
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
        let _: IntroEligibilityStatus = await purchases.checkTrialOrIntroDiscountEligibility(product: stp)
        let _: [String: IntroEligibility] = await purchases.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: [String]()
        )
        let _: [Package: IntroEligibility] = await purchases.checkTrialOrIntroDiscountEligibility(
            packages: [Package]()
        )
        let _: PromotionalOffer = try await purchases.promotionalOffer(
            forProductDiscount: discount,
            product: stp
        )
        let _: CustomerInfo = try await purchases.logOut()
        let _: Offerings = try await purchases.offerings()

        let _: Offerings? = try await purchases.syncAttributesAndOfferingsIfNeeded()

        let _: [StoreProduct] = await purchases.products([])
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack,
                                                                                      promotionalOffer: offer)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp,
                                                                                      promotionalOffer: offer)
        let _: CustomerInfo = try await purchases.customerInfo()
        let _: CustomerInfo = try await purchases.customerInfo(fetchPolicy: .default)
        let _: CustomerInfo = try await purchases.restorePurchases()
        let _: CustomerInfo = try await purchases.syncPurchases()

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            let result = try await StoreKit.Product.products(for: [""]).first!.purchase()
            let _: StoreTransaction? = try await purchases.recordPurchase(result)
        }

        for try await _: CustomerInfo in purchases.customerInfoStream {}

        #if os(iOS) || VISION_OS
        try await purchases.showManageSubscriptions()

        if #available(iOS 15.0, *) {
            let _: RefundRequestStatus = try await purchases.beginRefundRequest(forProduct: "")
            let _: RefundRequestStatus = try await purchases.beginRefundRequest(forEntitlement: "")
            let _: RefundRequestStatus = try await purchases.beginRefundRequestForActiveEntitlement()
        }

        let _: [PromotionalOffer] = await purchases.eligiblePromotionalOffers(forProduct: stp)
        #endif
    } catch {}
}

func checkNonAsyncMethods(_ purchases: Purchases) {
    #if os(iOS) || VISION_OS
    if #available(iOS 15.0, *) {
        purchases.beginRefundRequest(forProduct: "") { (_: Result<RefundRequestStatus, PublicError>) in }
        purchases.beginRefundRequest(forEntitlement: "") { (_: Result<RefundRequestStatus, PublicError>) in }
        purchases.beginRefundRequestForActiveEntitlement { (_: Result<RefundRequestStatus, PublicError>) in }
    }
    #endif
    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    if #available(iOS 16.0, *) {
        purchases.showStoreMessages { }
        purchases.showStoreMessages(for: [StoreMessageType.generic]) { }
    }
    #endif
}

private func checkConfigure() -> Purchases! {
    Purchases.configure(with: Configuration.Builder(withAPIKey: ""))
    Purchases.configure(with: Configuration.Builder(withAPIKey: "").build())
    Purchases.configure(with: Configuration.Builder(withAPIKey: "")
        .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .default)
        .build())
    Purchases.configure(with: Configuration.Builder(withAPIKey: "")
        .with(showStoreMessagesAutomatically: false)
        .build())

    Purchases.configure(withAPIKey: "")
    Purchases.configure(withAPIKey: "", appUserID: nil)
    Purchases.configure(withAPIKey: "", appUserID: nil, purchasesAreCompletedBy: .myApp, storeKitVersion: .default)

    return nil
}

private func checkPaywallsAPI(_ purchases: Purchases, _ event: PaywallEvent) async {
    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        await purchases.track(paywallEvent: event)
    }
}

@available(*, deprecated) // Ignore deprecation warnings
private func checkAsyncDeprecatedMethods(_ purchases: Purchases, _ stp: StoreProduct) async throws {
    let _: [PromotionalOffer] = await purchases.getEligiblePromotionalOffers(forProduct: stp)

    let _: [String: IntroEligibility] = await purchases.checkTrialOrIntroDiscountEligibility([String]())
    let _: PromotionalOffer = try await purchases.getPromotionalOffer(
        forProductDiscount: discount,
        product: stp
    )
    let _: (CustomerInfo, Bool) = try await purchases.logIn("")
}

@available(*, deprecated) // Ignore deprecation warnings
private func checkDeprecatedMethods(_ purchases: Purchases) {
    let _: Bool = Purchases.debugLogsEnabled

    Purchases.addAttributionData([String: Any](), from: AttributionNetwork.adjust, forNetworkUserId: "")
    Purchases.addAttributionData([String: Any](), from: AttributionNetwork.adjust, forNetworkUserId: nil)
    purchases.finishTransactions = true

    purchases.checkTrialOrIntroDiscountEligibility([String]()) { (_: [String: IntroEligibility]) in }

    purchases.logIn("") { (_: CustomerInfo?, _: Bool, _: Error?) in }

    Purchases.configure(withAPIKey: "", appUserID: "")

    let _: Bool = purchases.finishTransactions

}
