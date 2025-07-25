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
    let storeFrontCountryCode = purch.storeFrontCountryCode

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
         .trial,
         .prepaid:
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
         .generic,
         .winBackOffer:
        print(storeMessageType!)
    @unknown default:
        fatalError()
    }
}

private func checkStaticMethods() {
    let url: URL = URL(string: "https://example.com")!
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

private func checkExtensions() {
    let url: URL = URL(string: "https://example.com")!

    let webPurchaseRedemption: WebPurchaseRedemption? = url.asWebPurchaseRedemption

    print(webPurchaseRedemption!)
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
    let winBackOffer: WinBackOffer! = nil

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

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    var packageParamsBuilder = PurchaseParams.Builder(package: pack)
        .with(promotionalOffer: offer)

    #if ENABLE_TRANSACTION_METADATA
    packageParamsBuilder = packageParamsBuilder.with(metadata: ["foo":"bar"])
    #endif

    if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
        packageParamsBuilder = packageParamsBuilder.with(winBackOffer: winBackOffer)
    }
    let packageParams = packageParamsBuilder.build()

    var productParamsBuilder = PurchaseParams.Builder(product: storeProduct)
        .with(promotionalOffer: offer)

    #if ENABLE_TRANSACTION_METADATA
    productParamsBuilder = productParamsBuilder.with(metadata: ["foo":"bar"])
    #endif

    if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
        productParamsBuilder = packageParamsBuilder.with(winBackOffer: winBackOffer)
    }
    let productParams = productParamsBuilder.build()

    purchases.purchase(packageParams) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(productParams) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    #endif

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
    Task {
        let _: RevenueCat.Storefront? = await purchases.getStorefront()
        purchases.getStorefront { (_: RevenueCat.Storefront?) in }
    }
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
    let webPurchaseRedemption: WebPurchaseRedemption! = nil

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

        let storeProducts : [StoreProduct] = await purchases.products([])
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack,
                                                                                      promotionalOffer: offer)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp,
                                                                                      promotionalOffer: offer)

        var params = PurchaseParams.Builder(package: pack).with(promotionalOffer: offer)

        #if ENABLE_TRANSACTION_METADATA
        params = params.with(metadata: ["foo":"bar"])
        #endif

        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(params.build())

        let _: CustomerInfo = try await purchases.customerInfo()
        let _: CustomerInfo = try await purchases.customerInfo(fetchPolicy: .default)
        let _: CustomerInfo = try await purchases.restorePurchases()
        let _: CustomerInfo = try await purchases.syncPurchases()

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            let result = try await StoreKit.Product.products(for: [""]).first!.purchase()
            let _: StoreTransaction? = try await purchases.recordPurchase(result)
        }

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            let winBackOffersForProduct: [WinBackOffer] = try await purchases.eligibleWinBackOffers(
                forProduct: storeProducts.first!
            )

            purchases.eligibleWinBackOffers(
                forProduct: storeProducts.first!
            ) { (winBackOffers: [WinBackOffer]?, error: PublicError?) in
                return
            }

            let winBackOffersForPackage: [WinBackOffer] = try await purchases.eligibleWinBackOffers(forPackage: pack)
            purchases.eligibleWinBackOffers(
                forPackage: pack
            ) { (winBackOffers: [WinBackOffer]?, error: PublicError?) in
                return
            }
        }
        #endif

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

        let webPurchaseRedemptionResult: WebPurchaseRedemptionResult = await purchases.redeemWebPurchase(
            webPurchaseRedemption
        )
    } catch {}
}

func checkWebPurchaseRedemptionResult(result: WebPurchaseRedemptionResult) -> Bool {
    switch result {
    case let .success(customerInfo):
        let _: CustomerInfo = customerInfo
        return true
    case let .error(error):
        let _: PublicError = error
        return true
    case .invalidToken:
        return true
    case .purchaseBelongsToOtherUser:
        return true
    case let .expired(obfuscatedEmail):
        let _: String = obfuscatedEmail
        return true
    }
}

func checkNonAsyncMethods(_ purchases: Purchases) {
    let webPurchaseRedemption: WebPurchaseRedemption! = nil
    let redemptionCompletion: ((CustomerInfo?, PublicError?) -> Void)! = nil

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

    purchases.redeemWebPurchase(webPurchaseRedemption: webPurchaseRedemption, completion: redemptionCompletion)

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
        purchases.getProducts([""]) { (products: [StoreProduct]) in
            purchases.eligibleWinBackOffers(
                forProduct: products.first!
            ) { (winBackOffers: [WinBackOffer]?, error: Error?) in }
        }
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

private func checkVirtualCurrenciesAPI(_ purchases: Purchases) async throws {

    // Fetching Virtual Currencies
    purchases.getVirtualCurrencies(completion: { (virtualCurrencies: VirtualCurrencies?, error: PublicError?) in })
    purchases.getVirtualCurrencies() { (virtualCurrencies: VirtualCurrencies?, error: PublicError?) in }
    let _: VirtualCurrencies = try await purchases.virtualCurrencies()

    // Invalidating Virtual Currencies Cache
    purchases.invalidateVirtualCurrenciesCache()

    // Cached virtual currencies
    let _: VirtualCurrencies? = purchases.cachedVirtualCurrencies
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
