//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WinBackEligibilityAdapters.swift
//
//  Created by Will Taylor on 5/28/26.

import StoreKit

// This file isolates StoreKit-backed win-back eligibility adapters behind simple internal protocols.
// That keeps the WinBackEligibilityCalculator's core logic easy to unit test with mocks,
// without instantiating StoreKit types or relying on StoreKit configuration files.
//
// We need to do this to make WinBackEligibilityCalculator testable since there's a bug that
// prevents us from loading SKConfig files with SKTestSession in iOS 26.4+, and the APIs
// for evaluating winback offer eligibility on billing plans are only available on Xcode 26.5+.
// For more information on this bug, refer to:
//    - https://developer.apple.com/forums/thread/826971
//    - FB22500243
// When this issue is resolved, we may be able to replace this dependency inversion
// and its associated tests with SKTestSession-based tests.

// MARK: - Testable StoreKit-free types
internal enum WinBackEligibilityOwnershipType: Sendable {
    case purchased
    case familyShared
    case unknown
}

internal protocol WinBackEligibilityProductType: Sendable {
    var currencyCode: String? { get }
    var billingPlanType: BillingPlanType? { get }
    var subscriptionInfo: (any WinBackEligibilitySubscriptionInfoType)? { get }
}

internal protocol WinBackEligibilitySubscriptionInfoType: Sendable {
    func statuses() async throws -> [any WinBackEligibilityStatusType]

    var winBackOffers: [any WinBackEligibilityOfferType] { get }
    var pricingTerms: [any WinBackEligibilityPricingTermsType] { get }
}

internal protocol WinBackEligibilityStatusType: Sendable {
    var ownershipType: WinBackEligibilityOwnershipType { get }
    var verifiedRenewalInfo: (any WinBackEligibilityRenewalInfoType)? { get }
}

internal protocol WinBackEligibilityRenewalInfoType: Sendable {
    var eligibleWinBackOfferIDs: [String] { get }
}

internal protocol WinBackEligibilityOfferType: Sendable {
    var id: String? { get }
    var type: StoreProductDiscount.DiscountType { get }

    func storeProductDiscount(currencyCode: String?) -> StoreProductDiscount?
}

internal protocol WinBackEligibilityPricingTermsType: Sendable {
    var billingPlanType: BillingPlanType? { get }
    var subscriptionOffers: [any WinBackEligibilityOfferType] { get }
}

// MARK: - StoreKit adapters

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension WinBackOfferEligibilityCalculator {

    func storeKitWinBackEligibilityProduct(from product: StoreProduct) -> (any WinBackEligibilityProductType)? {
        guard let subscriptionInfo = product.sk2Product?.subscription else {
            return nil
        }

        return StoreKitWinBackProduct(
            currencyCode: product.currencyCode,
            billingPlanType: self.storeKitWinBackBillingPlanType(from: product),
            subscriptionInfo: StoreKitWinBackSubscriptionInfo(subscriptionInfo)
        )
    }

    private func storeKitWinBackBillingPlanType(from product: StoreProduct) -> BillingPlanType? {
        #if compiler(>=6.3.2)
        if #available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, visionOS 26.4, *) {
            return product.installmentsInfo?.billingPlanType
        } else {
            return nil
        }
        #else
        return nil
        #endif
    }
}

private struct StoreKitWinBackProduct: WinBackEligibilityProductType {
    let currencyCode: String?
    let billingPlanType: BillingPlanType?
    let subscriptionInfo: (any WinBackEligibilitySubscriptionInfoType)?
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct StoreKitWinBackSubscriptionInfo: WinBackEligibilitySubscriptionInfoType {

    private let subscriptionInfo: Product.SubscriptionInfo

    init(_ subscriptionInfo: Product.SubscriptionInfo) {
        self.subscriptionInfo = subscriptionInfo
    }

    func statuses() async throws -> [any WinBackEligibilityStatusType] {
        return try await self.subscriptionInfo.status.map(StoreKitWinBackStatus.init)
    }

    var winBackOffers: [any WinBackEligibilityOfferType] {
        #if compiler(>=6.0)
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return self.subscriptionInfo.winBackOffers.map(StoreKitWinBackOffer.init)
        } else {
            return []
        }
        #else
        return []
        #endif
    }

    var pricingTerms: [any WinBackEligibilityPricingTermsType] {
        #if compiler(>=6.3.2)
        if #available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, visionOS 26.4, *) {
            return self.subscriptionInfo.pricingTerms.map(StoreKitWinBackPricingTerms.init)
        } else {
            return []
        }
        #else
        return []
        #endif
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct StoreKitWinBackStatus: WinBackEligibilityStatusType {

    private let status: Product.SubscriptionInfo.Status

    init(_ status: Product.SubscriptionInfo.Status) {
        self.status = status
    }

    var ownershipType: WinBackEligibilityOwnershipType {
        switch self.status.transaction.unsafePayloadValue.ownershipType {
        case .purchased:
            return .purchased
        case .familyShared:
            return .familyShared
        default:
            return .unknown
        }
    }

    var verifiedRenewalInfo: (any WinBackEligibilityRenewalInfoType)? {
        return self.status.verifiedRenewalInfo.map(StoreKitWinBackRenewalInfo.init)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct StoreKitWinBackRenewalInfo: WinBackEligibilityRenewalInfoType {

    private let renewalInfo: Product.SubscriptionInfo.RenewalInfo

    init(_ renewalInfo: Product.SubscriptionInfo.RenewalInfo) {
        self.renewalInfo = renewalInfo
    }

    var eligibleWinBackOfferIDs: [String] {
        #if compiler(>=6.0)
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return self.renewalInfo.eligibleWinBackOfferIDs
        } else {
            return []
        }
        #else
        return []
        #endif
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct StoreKitWinBackOffer: WinBackEligibilityOfferType {

    private let offer: Product.SubscriptionOffer

    init(_ offer: Product.SubscriptionOffer) {
        self.offer = offer
    }

    var id: String? {
        return self.offer.id
    }

    var type: StoreProductDiscount.DiscountType {
        return StoreProductDiscount.DiscountType.from(sk2Discount: self.offer) ?? .promotional
    }

    func storeProductDiscount(currencyCode: String?) -> StoreProductDiscount? {
        return StoreProductDiscount(sk2Discount: self.offer, currencyCode: currencyCode)
    }
}

@available(iOS 26.4, tvOS 26.4, macOS 26.4, watchOS 26.4, visionOS 26.4, *)
private struct StoreKitWinBackPricingTerms: WinBackEligibilityPricingTermsType {

    #if compiler(>=6.3.2)
    private let pricingTerms: Product.SubscriptionInfo.PricingTerms

    init(_ pricingTerms: Product.SubscriptionInfo.PricingTerms) {
        self.pricingTerms = pricingTerms
    }
    #endif

    var billingPlanType: BillingPlanType? {
        #if compiler(>=6.3.2)
        return BillingPlanType.from(storeKitBillingPlanType: self.pricingTerms.billingPlanType)
        #else
        return nil
        #endif
    }

    var subscriptionOffers: [any WinBackEligibilityOfferType] {
        #if compiler(>=6.3.2)
        return self.pricingTerms.subscriptionOffers.map(StoreKitWinBackOffer.init)
        #else
        return []
        #endif
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension StoreKit.Product.SubscriptionInfo.Status {
    var verifiedRenewalInfo: StoreKit.Product.SubscriptionInfo.RenewalInfo? {
        switch self.renewalInfo {
        case .unverified:
            Logger.warn(
                Strings.storeKit.sk2_unverified_renewal_info(
                    productIdentifier: String(self.transaction.underlyingTransaction.productID)
                )
            )
            return nil
        case .verified(let status):
            return status
        }
    }
}
