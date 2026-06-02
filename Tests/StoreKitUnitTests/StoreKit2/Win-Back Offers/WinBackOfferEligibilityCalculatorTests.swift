//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WinBackOfferEligibilityCalculatorTests.swift
//
//  Created by Will Taylor on 5/27/26.

import Nimble
@testable @_spi(Internal) import RevenueCat
import XCTest

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
final class WinBackOfferEligibilityCalculatorTests: TestCase {

    private var calculator: WinBackOfferEligibilityCalculator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS18APIAvailableOrSkipTest()

        self.calculator = WinBackOfferEligibilityCalculator(
            systemInfo: MockSystemInfo(finishTransactions: true, storeKitVersion: .storeKit2)
        )
    }

    func testReturnsEmptyForProductWithoutSubscriptionInfo() async {
        let product = MockWinBackEligibilityProduct(subscriptionInfo: nil)

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers).to(beEmpty())
    }

    func testReturnsEmptyWhenStatusLookupFails() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(statusesResult: .failure(MockError.mockError))
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers).to(beEmpty())
    }

    func testReturnsEmptyWhenThereAreNoStatuses() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(statuses: [])
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers).to(beEmpty())
    }

    func testReturnsEmptyWhenPurchasedStatusHasNoVerifiedRenewalInfo() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .purchased,
                        verifiedRenewalInfo: nil
                    )
                ],
                winBackOffers: [MockWinBackEligibilityOffer.winBack(identifier: "winback_offer")]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers).to(beEmpty())
    }

    func testReturnsEmptyForUnknownOwnershipType() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .unknown,
                        eligibleWinBackOfferIDs: ["winback_offer"]
                    )
                ],
                winBackOffers: [MockWinBackEligibilityOffer.winBack(identifier: "winback_offer")]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers).to(beEmpty())
    }

    func testReturnsEligibleWinBackOffersInOrder() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .purchased,
                        eligibleWinBackOfferIDs: ["first_offer", "second_offer"]
                    )
                ],
                winBackOffers: [
                    MockWinBackEligibilityOffer.winBack(identifier: "first_offer"),
                    MockWinBackEligibilityOffer.winBack(identifier: "second_offer"),
                    MockWinBackEligibilityOffer.winBack(identifier: "ineligible_offer")
                ]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers.map(\.discount.offerIdentifier)) == ["first_offer", "second_offer"]
    }

    func testFiltersOutEligibleIDsThatDoNotHaveAvailableWinBackOffers() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .purchased,
                        eligibleWinBackOfferIDs: ["available_offer", "missing_offer"]
                    )
                ],
                winBackOffers: [MockWinBackEligibilityOffer.winBack(identifier: "available_offer")]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers.map(\.discount.offerIdentifier)) == ["available_offer"]
    }

    func testReturnsSubscriptionInfoWinBackOfferForNonMonthlyProduct() async {
        let product = MockWinBackEligibilityProduct(
            subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .year),
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .purchased,
                        eligibleWinBackOfferIDs: ["annual_offer"]
                    )
                ],
                winBackOffers: [MockWinBackEligibilityOffer.winBack(identifier: "annual_offer")]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers.map(\.discount.offerIdentifier)) == ["annual_offer"]
    }

    func testIgnoresNonWinBackOffersFromPricingTerms() async throws {
        let product = MockWinBackEligibilityProduct(
            billingPlanType: .monthly,
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .purchased,
                        eligibleWinBackOfferIDs: ["promo_offer", "winback_offer"]
                    )
                ],
                pricingTerms: [
                    MockWinBackEligibilityPricingTerms(
                        billingPlanType: .monthly,
                        subscriptionOffers: [
                            MockWinBackEligibilityOffer.promotional(identifier: "promo_offer"),
                            MockWinBackEligibilityOffer.winBack(identifier: "winback_offer")
                        ]
                    )
                ]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers.map(\.discount.offerIdentifier)) == ["winback_offer"]
    }

    func testFiltersWinBackOffersToProductBillingPlan() async throws {
        let product = MockWinBackEligibilityProduct(
            billingPlanType: .monthly,
            subscriptionInfo: MockWinBackEligibilitySubscriptionInfo(
                statuses: [
                    MockWinBackEligibilityStatus(
                        ownershipType: .purchased,
                        eligibleWinBackOfferIDs: ["upfront_offer", "monthly_offer"]
                    )
                ],
                pricingTerms: [
                    MockWinBackEligibilityPricingTerms(
                        billingPlanType: .upFront,
                        subscriptionOffers: [MockWinBackEligibilityOffer.winBack(identifier: "upfront_offer")]
                    ),
                    MockWinBackEligibilityPricingTerms(
                        billingPlanType: .monthly,
                        subscriptionOffers: [MockWinBackEligibilityOffer.winBack(identifier: "monthly_offer")]
                    )
                ]
            )
        )

        let offers = await self.calculator.calculateEligibleWinBackOffers(forProduct: product)

        expect(offers.map(\.discount.offerIdentifier)) == ["monthly_offer"]
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct MockWinBackEligibilityProduct: WinBackEligibilityProductType {

    let product: TestStoreProduct
    let subscriptionInfo: (any WinBackEligibilitySubscriptionInfoType)?

    var currencyCode: String? {
        return self.product.currencyCode
    }

    var billingPlanType: BillingPlanType? {
        return self.product.installmentsInfo?.billingPlanType
    }

    init(
        currencyCode: String = "USD",
        billingPlanType: BillingPlanType? = nil,
        subscriptionPeriod: SubscriptionPeriod = SubscriptionPeriod(value: 1, unit: .month),
        subscriptionInfo: (any WinBackEligibilitySubscriptionInfoType)? = MockWinBackEligibilitySubscriptionInfo()
    ) {
        self.product = Self.product(
            currencyCode: currencyCode,
            billingPlanType: billingPlanType,
            subscriptionPeriod: subscriptionPeriod
        )
        self.subscriptionInfo = subscriptionInfo
    }

    init(
        product: TestStoreProduct,
        subscriptionInfo: (any WinBackEligibilitySubscriptionInfoType)? = MockWinBackEligibilitySubscriptionInfo()
    ) {
        self.product = product
        self.subscriptionInfo = subscriptionInfo
    }

    private static func product(
        currencyCode: String,
        billingPlanType: BillingPlanType?,
        subscriptionPeriod: SubscriptionPeriod
    ) -> TestStoreProduct {
        return TestStoreProduct(
            localizedTitle: "product",
            price: 3.99,
            currencyCode: currencyCode,
            localizedPriceString: "$3.99",
            productIdentifier: "product",
            productType: .autoRenewableSubscription,
            localizedDescription: "",
            subscriptionPeriod: subscriptionPeriod,
            locale: Locale(identifier: "en_US"),
            installmentsInfo: billingPlanType.map(Self.installmentsInfo)
        )
    }

    private static func installmentsInfo(billingPlanType: BillingPlanType) -> InstallmentsInfo {
        return InstallmentsInfo(
            commitmentInstallmentsCount: 3,
            commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
            installmentBillingPrice: 3.99,
            installmentBillingDisplayPrice: "$3.99",
            commitmentTotalPeriod: SubscriptionPeriod(value: 3, unit: .month),
            commitmentTotalPrice: 11.97,
            commitmentTotalDisplayPrice: "$11.97",
            billingPlanType: billingPlanType
        )
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct MockWinBackEligibilitySubscriptionInfo: WinBackEligibilitySubscriptionInfoType {

    let statusesResult: Result<[any WinBackEligibilityStatusType], Error>
    let winBackOffers: [any WinBackEligibilityOfferType]
    let pricingTerms: [any WinBackEligibilityPricingTermsType]

    init(
        statuses: [any WinBackEligibilityStatusType] = [],
        winBackOffers: [any WinBackEligibilityOfferType] = [],
        pricingTerms: [any WinBackEligibilityPricingTermsType] = []
    ) {
        self.statusesResult = .success(statuses)
        self.winBackOffers = winBackOffers
        self.pricingTerms = pricingTerms
    }

    init(
        statusesResult: Result<[any WinBackEligibilityStatusType], Error>,
        winBackOffers: [any WinBackEligibilityOfferType] = [],
        pricingTerms: [any WinBackEligibilityPricingTermsType] = []
    ) {
        self.statusesResult = statusesResult
        self.winBackOffers = winBackOffers
        self.pricingTerms = pricingTerms
    }

    func statuses() async throws -> [any WinBackEligibilityStatusType] {
        return try self.statusesResult.get()
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct MockWinBackEligibilityStatus: WinBackEligibilityStatusType {

    let ownershipType: WinBackEligibilityOwnershipType
    let verifiedRenewalInfo: (any WinBackEligibilityRenewalInfoType)?

    init(
        ownershipType: WinBackEligibilityOwnershipType,
        eligibleWinBackOfferIDs: [String]
    ) {
        self.ownershipType = ownershipType
        self.verifiedRenewalInfo = MockWinBackEligibilityRenewalInfo(
            eligibleWinBackOfferIDs: eligibleWinBackOfferIDs
        )
    }

    init(
        ownershipType: WinBackEligibilityOwnershipType,
        verifiedRenewalInfo: (any WinBackEligibilityRenewalInfoType)?
    ) {
        self.ownershipType = ownershipType
        self.verifiedRenewalInfo = verifiedRenewalInfo
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct MockWinBackEligibilityRenewalInfo: WinBackEligibilityRenewalInfoType {

    let eligibleWinBackOfferIDs: [String]

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct MockWinBackEligibilityOffer: WinBackEligibilityOfferType {

    let id: String?
    let type: RevenueCat.StoreProductDiscount.DiscountType?

    func storeProductDiscount(currencyCode: String?) -> StoreProductDiscount? {
        guard let type else { return nil }

        return TestStoreProductDiscount(
            identifier: self.id ?? "",
            price: 0,
            localizedPriceString: "$0.00",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: type
        ).toStoreProductDiscount()
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private extension WinBackEligibilityOfferType where Self == MockWinBackEligibilityOffer {

    static func winBack(identifier: String) -> Self {
        return .init(id: identifier, type: .winBack)
    }

    static func promotional(identifier: String) -> Self {
        return .init(id: identifier, type: .promotional)
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct MockWinBackEligibilityPricingTerms: WinBackEligibilityPricingTermsType {

    let billingPlanType: BillingPlanType?
    let subscriptionOffers: [any WinBackEligibilityOfferType]

}

private enum MockError: Error {
    case mockError
}
