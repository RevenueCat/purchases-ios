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
import RevenueCat_CustomEntitlementComputation
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

    _ = Task<Void, Never> {
        await checkAsyncMethods(purchases: purch)
        await checkPromoOffers(purchases: purch)
    }

    checkNonAsyncMethods(purch)
}

var periodType: PeriodType!
var oType: PurchaseOwnershipType!
var logLevel: LogLevel!
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

    // swiftlint:disable:next line_length
    let purchaseCompletedBlock: PurchaseCompletedBlock = { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }

    let startPurchaseBlock: StartPurchaseBlock = { (_: PurchaseCompletedBlock) in }

    print(purchaseResultData,
          purchaseCompletedBlock,
          startPurchaseBlock)
}

private func checkPurchasesPurchasingAPI(purchases: Purchases) {
    purchases.getOfferings { (_: Offerings?, _: Error?) in }
    purchases.getProducts([String]()) { (_: [StoreProduct]) in }

    let storeProduct: StoreProduct! = nil
    let pack: Package! = nil

    purchases.purchase(product: storeProduct) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    purchases.purchase(package: pack) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }
    let purchaseParams: PurchaseParams! = nil
    purchases.purchase(purchaseParams) { (_: StoreTransaction?, _: CustomerInfo?, _: Error?, _: Bool) in }

    purchases.restorePurchases()
    purchases.restorePurchases { (_: CustomerInfo?, _: PublicError?) in }

    if #available(iOS 14.0, *) {
#if os(iOS)
        purchases.presentCodeRedemptionSheet()
#endif
    }

    // PurchasesDelegate
    let customerInfo: CustomerInfo? = nil
    purchases.delegate?.purchases?(purchases, receivedUpdated: customerInfo!)

    let purchaseBlock = { (_: @MainActor @Sendable (StoreTransaction?, CustomerInfo?, PublicError?, Bool) -> Void) in }
    purchases.delegate?.purchases?(purchases, readyForPromotedProduct: storeProduct, purchase: purchaseBlock)
}

private func checkPromoOffers(purchases: Purchases) async {
    let discount: StoreProductDiscount! = nil
    let product: StoreProduct! = nil
    purchases.getPromotionalOffer(forProductDiscount: discount,
                                  product: product) { (_: PromotionalOffer?, _: Error?) in }

    do {
        let _: PromotionalOffer = try await purchases.promotionalOffer(forProductDiscount: discount, product: product)
    } catch {}
    let _: [PromotionalOffer] = await purchases.eligiblePromotionalOffers(forProduct: product)
}

private func checkIdentity(purchases: Purchases) {
    purchases.switchUser(to: "")
}

private func checkPurchasesSupportAPI(purchases: Purchases) {
    #if os(iOS)
    purchases.showManageSubscriptions { _ in }
    #endif
    if #available(iOS 13.4, *) {
#if os(iOS) || targetEnvironment(macCatalyst)
        _ = purchases.showPriceConsentIfNeeded
        _ = purchases.delegate?.shouldShowPriceConsent
#endif
    }
}

private func checkPurchaseParams() {
    let pack: Package! = nil
    let storeProduct: StoreProduct! = nil
    let offer: PromotionalOffer! = nil

    let packageParamsBuilder = PurchaseParams.Builder(package: pack)
        .with(promotionalOffer: offer)
        .with(quantity: 3)

    if #available(iOS 15.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        let _ = PurchaseParams.Builder(package: pack)
            .with(
                promotionalOfferOptions: StoreKit2PromotionalOfferPurchaseOptions(
                    offerID: "abc",
                    compactJWS: "123"
                )
            )
    }

    if #available(iOS 15.0, macOS 15.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *) {
        let _ = PurchaseParams.Builder(package: pack)
            .with(introductoryOfferEligibilityJWS: "abc123")
    }

    let _: PurchaseParams = packageParamsBuilder.build()

    let productParamsBuilder = PurchaseParams.Builder(product: storeProduct)
        .with(promotionalOffer: offer)
        .with(quantity: 5)

    if #available(iOS 15.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        let _ = PurchaseParams.Builder(product: storeProduct)
            .with(
                promotionalOfferOptions: StoreKit2PromotionalOfferPurchaseOptions(
                    offerID: "abc",
                    compactJWS: "123"
                )
            )
    }

    if #available(iOS 15.0, macOS 15.4, tvOS 18.4, watchOS 11.4, visionOS 2.4, *) {
        let _ = PurchaseParams.Builder(product: storeProduct)
            .with(introductoryOfferEligibilityJWS: "abc123")
    }

    let _: PurchaseParams = productParamsBuilder.build()
}

private func checkAsyncMethods(purchases: Purchases) async {
    let pack: Package! = nil
    let stp: StoreProduct! = nil
    let promoOffer: PromotionalOffer! = nil

    do {
        let _: Offerings = try await purchases.offerings()

        let _: [StoreProduct] = await purchases.products([])
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(package: pack,
                                                                                      promotionalOffer: promoOffer)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp)
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(product: stp,
                                                                                      promotionalOffer: promoOffer)
        let params = PurchaseParams.Builder(package: pack)
            .with(promotionalOffer: promoOffer)
            .with(quantity: 4)
            .build()
        let _: (StoreTransaction?, CustomerInfo, Bool) = try await purchases.purchase(params)

        for try await _: CustomerInfo in purchases.customerInfoStream {}

        let _: CustomerInfo = try await purchases.restorePurchases()

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            let _: Bool = try await purchases.isPurchaseAllowedByRestoreBehavior()
        }

        if #available(iOS 15.0, *) {
#if os(iOS)
            try await purchases.showManageSubscriptions()
            let _: RefundRequestStatus = try await purchases.beginRefundRequest(forProduct: "")
            let _: RefundRequestStatus = try await purchases.beginRefundRequest(forEntitlement: "")
            let _: RefundRequestStatus = try await purchases.beginRefundRequestForActiveEntitlement()
#endif
        }

        let _: [String: IntroEligibility] = await purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: [""])
        let _: [Package: IntroEligibility] = await purchases.checkTrialOrIntroDiscountEligibility(packages: [pack])
        let _: IntroEligibilityStatus = await purchases.checkTrialOrIntroDiscountEligibility(product: stp)
    } catch {}
}

func checkNonAsyncMethods(_ purchases: Purchases) {
    let storeProduct: StoreProduct! = nil

    if #available(iOS 15.0, *) {
#if os(iOS)
        purchases.beginRefundRequest(forProduct: "") { (_: Result<RefundRequestStatus, PublicError>) in }
        purchases.beginRefundRequest(forEntitlement: "") { (_: Result<RefundRequestStatus, PublicError>) in }
        purchases.beginRefundRequestForActiveEntitlement { (_: Result<RefundRequestStatus, PublicError>) in }
#endif
    }

    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        purchases.isPurchaseAllowedByRestoreBehavior { (_: Bool?, _: PublicError?) in }
    }

    purchases.checkTrialOrIntroDiscountEligibility(
        productIdentifiers: [""],
        completion: { eligibilityDictionary in
            let _: [String: IntroEligibility] = eligibilityDictionary
        }
    )
    purchases.checkTrialOrIntroDiscountEligibility(product: storeProduct) { introEligibilityStatus in
        let _: IntroEligibilityStatus = introEligibilityStatus
    }
}

private func checkConfigure() -> Purchases! {
    Purchases.configureInCustomEntitlementsComputationMode(
        apiKey: "",
        appUserID: ""
    )
    Purchases.configureInCustomEntitlementsComputationMode(
        apiKey: "",
        appUserID: "",
        showStoreMessagesAutomatically: false
    )

    let configuration = Configuration.Builder(withAPIKey: "", appUserID: "").build()
    Purchases.configure(with: configuration)

    return nil
}

private func checkConfigurationAndBuilder(_ appUserID: String) {
    let builder: Configuration.Builder = .init(withAPIKey: "", appUserID: appUserID)
        .with(showStoreMessagesAutomatically: true)
        .with(storeKitVersion: StoreKitVersion.storeKit1)
        .with(apiKey: "anotherAPIKey")
    let _: Configuration = builder.build()
}
