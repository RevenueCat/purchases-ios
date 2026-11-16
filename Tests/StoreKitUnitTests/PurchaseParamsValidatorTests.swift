//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseParamsValidatorTests.swift
//
//  Created by Will Taylor on 11/16/26.

import Nimble
@testable @_spi(Internal) @_spi(Experimental) import RevenueCat
import StoreKit
import XCTest

// Lives in StoreKitUnitTests so the SK2 tests can use real `StoreKit.Product`s
// from `UnitTestsConfiguration.storekit`.
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchaseParamsValidatorTests: StoreKitConfigTestCase {

    let validator = PurchaseParamsValidator(systemInfo: MockSystemInfo(finishTransactions: true))

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

}

// MARK: - SK1 Happy Path
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchaseParamsValidatorTests {

    func testSK1ConsumableProductPassesValidation() {
        self.expectValidationToPass(.init(product: Self.sk1Product(Self.consumableID, isSubscription: false)))
    }

    func testSK1ConsumablePackagePassesValidation() {
        let product = Self.sk1Product(Self.consumableID, isSubscription: false)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

    func testSK1NonConsumableProductPassesValidation() {
        self.expectValidationToPass(.init(product: Self.sk1Product(Self.nonConsumableID, isSubscription: false)))
    }

    func testSK1NonConsumablePackagePassesValidation() {
        let product = Self.sk1Product(Self.nonConsumableID, isSubscription: false)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

    func testSK1SubscriptionProductPassesValidation() {
        self.expectValidationToPass(.init(product: Self.sk1Product(Self.monthlyID, isSubscription: true)))
    }

    func testSK1SubscriptionPackagePassesValidation() {
        let product = Self.sk1Product(Self.monthlyID, isSubscription: true)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

}

// MARK: - SK2 Happy Path
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchaseParamsValidatorTests {

    func testSK2ConsumableProductPassesValidation() async throws {
        let product = try await self.sk2Product(Self.consumableID)
        self.expectValidationToPass(.init(product: product))
    }

    func testSK2ConsumablePackagePassesValidation() async throws {
        let product = try await self.sk2Product(Self.consumableID)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

    func testSK2NonConsumableProductPassesValidation() async throws {
        let product = try await self.sk2Product(Self.nonConsumableID)
        self.expectValidationToPass(.init(product: product))
    }

    func testSK2NonConsumablePackagePassesValidation() async throws {
        let product = try await self.sk2Product(Self.nonConsumableID)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

    func testSK2SubscriptionProductPassesValidation() async throws {
        let product = try await self.sk2Product(Self.annualID)
        self.expectValidationToPass(.init(product: product))
    }

    func testSK2SubscriptionPackagePassesValidation() async throws {
        let product = try await self.sk2Product(Self.annualID)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

    func testSK2MonthlyProductPassesValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToPass(.init(product: product))
    }

    func testSK2MonthlyPackagePassesValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

    func testSK2MonthlyWithCommitmentProductPassesValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyWithCommitmentID)
        self.expectValidationToPass(.init(product: product))
    }

    func testSK2MonthlyWithCommitmentPackagePassesValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyWithCommitmentID)
        self.expectValidationToPass(.init(package: Self.package(with: product)))
    }

}

// MARK: - Test Store Happy Path
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchaseParamsValidatorTests {

    func testTestStoreProductPassesValidation() {
        self.expectValidationToPass(.init(product: Self.testStoreProduct()))
    }

}

// MARK: - Multiseat Purchases
#if ENABLE_MULTISEAT_PURCHASES
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension PurchaseParamsValidatorTests {

    func testParamsWithOneSeatPassValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToPass(PurchaseParams.Builder(product: product).with(seats: 1))
    }

    func testParamsWithMultipleSeatsPassValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToPass(PurchaseParams.Builder(package: Self.package(with: product)).with(seats: 25))
    }

    func testParamsWithMaxIntSeatsPassValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToPass(PurchaseParams.Builder(product: product).with(seats: Int.max))
    }

    func testParamsWithZeroSeatsFailValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToFail(PurchaseParams.Builder(product: product).with(seats: 0))
    }

    func testParamsWithNegativeSeatsFailValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToFail(PurchaseParams.Builder(product: product).with(seats: -3))
    }

    func testParamsWithSeatsForTestStoreProductFailValidation() {
        self.expectValidationToFail(PurchaseParams.Builder(product: Self.testStoreProduct()).with(seats: 2))
    }

    func testParamsWithSeatsForTestStorePackageFailValidation() {
        let package = Self.package(with: Self.testStoreProduct())
        self.expectValidationToFail(PurchaseParams.Builder(package: package).with(seats: 2))
    }

    // MARK: Quantity

    func testParamsWithQuantityAndNoSeatsPassValidation() async throws {
        let product = try await self.sk2Product(Self.consumableID)
        self.expectValidationToPass(PurchaseParams.Builder(product: product).with(quantity: 3))
    }

    func testParamsWithSeatsAndQuantityFailValidation() async throws {
        let product = try await self.sk2Product(Self.monthlyID)
        self.expectValidationToFail(PurchaseParams.Builder(product: product).with(quantity: 2).with(seats: 2))
    }

    func testParamsWithSeatsAndQuantityForPackageFailValidation() async throws {
        let package = Self.package(with: try await self.sk2Product(Self.monthlyID))
        self.expectValidationToFail(PurchaseParams.Builder(package: package).with(seats: 2).with(quantity: 2))
    }

    // MARK: StoreKit 1

    func testParamsWithoutSeatsPassValidationWhenUsingStoreKit1() {
        let product = Self.sk1Product(Self.monthlyID, isSubscription: true)
        self.expectValidationToPass(PurchaseParams.Builder(product: product),
                                    validator: Self.storeKit1Validator())
    }

    func testParamsWithSeatsFailValidationWhenUsingStoreKit1() {
        let product = Self.sk1Product(Self.monthlyID, isSubscription: true)
        self.expectValidationToFail(PurchaseParams.Builder(product: product).with(seats: 2),
                                    errorCode: .featureNotSupportedWithStoreKit1,
                                    validator: Self.storeKit1Validator())
    }

    func testParamsWithSeatsForPackageFailValidationWhenUsingStoreKit1() {
        let package = Self.package(with: Self.sk1Product(Self.monthlyID, isSubscription: true))
        self.expectValidationToFail(PurchaseParams.Builder(package: package).with(seats: 2),
                                    errorCode: .featureNotSupportedWithStoreKit1,
                                    validator: Self.storeKit1Validator())
    }

    func testParamsWithSeatsForSK1ProductFailValidationWhenUsingStoreKit2() {
        let product = Self.sk1Product(Self.monthlyID, isSubscription: true)
        self.expectValidationToFail(PurchaseParams.Builder(product: product).with(seats: 2),
                                    errorCode: .featureNotSupportedWithStoreKit1,
                                    validator: Self.storeKit2Validator())
    }

    func testParamsWithSeatsForSK1PackageFailValidationWhenUsingStoreKit2() {
        let package = Self.package(with: Self.sk1Product(Self.monthlyID, isSubscription: true))
        self.expectValidationToFail(PurchaseParams.Builder(package: package).with(seats: 2),
                                    errorCode: .featureNotSupportedWithStoreKit1,
                                    validator: Self.storeKit2Validator())
    }

    func testParamsWithoutSeatsForSK1ProductPassValidationWhenUsingStoreKit2() {
        let product = Self.sk1Product(Self.monthlyID, isSubscription: true)
        self.expectValidationToPass(PurchaseParams.Builder(product: product),
                                    validator: Self.storeKit2Validator())
    }

}
#endif

// MARK: - Helpers
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension PurchaseParamsValidatorTests {

    // Product IDs from `UnitTestsConfiguration.storekit`.
    static let consumableID = "com.revenuecat.consumable"
    static let nonConsumableID = "lifetime"
    static let monthlyID = "com.revenuecat.monthly_4.99.1_week_intro"
    static let annualID = "com.revenuecat.annual_39.99_no_trial"
    static let monthlyWithCommitmentID = "com.revenuecat.sampleapp.monthly.12mocommitment"

    func expectValidationToPass(_ builder: PurchaseParams.Builder, validator: PurchaseParamsValidator? = nil) {
        let validator = validator ?? self.validator
        let params = builder.build()
        expect { try validator.validate(purchaseParams: params) }.toNot(throwError())
    }

    func expectValidationToFail(_ builder: PurchaseParams.Builder,
                                errorCode: ErrorCode = .purchaseInvalidError,
                                validator: PurchaseParamsValidator? = nil) {
        let validator = validator ?? self.validator
        let params = builder.build()
        expect { try validator.validate(purchaseParams: params) }.to(throwError(errorCode))
    }

    static func storeKit1Validator() -> PurchaseParamsValidator {
        return PurchaseParamsValidator(systemInfo: MockSystemInfo(finishTransactions: true,
                                                                  storeKitVersion: .storeKit1))
    }

    static func storeKit2Validator() -> PurchaseParamsValidator {
        return PurchaseParamsValidator(systemInfo: MockSystemInfo(finishTransactions: true,
                                                                  storeKitVersion: .storeKit2))
    }

    /// SK1 has no notion of consumable vs. non-consumable: both are products without a subscription period.
    static func sk1Product(_ identifier: String, isSubscription: Bool) -> StoreProduct {
        let product = MockSK1Product(mockProductIdentifier: identifier)
        if !isSubscription {
            product.mockSubscriptionPeriod = nil
        }
        return StoreProduct(sk1Product: product)
    }

    func sk2Product(_ productID: String) async throws -> StoreProduct {
        return StoreProduct(sk2Product: try await self.fetchSk2Product(productID))
    }

    static func testStoreProduct() -> StoreProduct {
        return TestStoreProduct(
            localizedTitle: "Test Product",
            price: 4.99,
            currencyCode: "USD",
            localizedPriceString: "$4.99",
            productIdentifier: "test.product",
            productType: .autoRenewableSubscription,
            localizedDescription: "Test subscription",
            locale: Locale(identifier: "en_US")
        ).toStoreProduct()
    }

    static func package(with product: StoreProduct) -> Package {
        return Package(identifier: "package",
                       packageType: .custom,
                       storeProduct: product,
                       offeringIdentifier: "offering",
                       webCheckoutUrl: nil)
    }

}
