//
//  StoreKitIntegrationTests.swift
//  StoreKitIntegrationTests
//
//  Created by Andrés Boedo on 5/3/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Nimble
@testable import RevenueCat
import StoreKit
import StoreKitTest
import UniformTypeIdentifiers
import XCTest

// swiftlint:disable file_length type_body_length

class StoreKit2IntegrationTests: StoreKit1IntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

}

class StoreKit1IntegrationTests: BaseStoreKitIntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting {
        return .disabled
    }

    func testIsSandbox() {
        expect(Purchases.shared.isSandbox) == true
    }

    func testPurchasesDiagnostics() async throws {
        let diagnostics = PurchasesDiagnostics(purchases: Purchases.shared)

        try await diagnostics.testSDKHealth()
    }

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await Purchases.shared.offerings()
        expect(receivedOfferings.all).toNot(beEmpty())
    }

    func testCanPurchasePackage() async throws {
        try await self.purchaseMonthlyOffering()
    }

    func testCanPurchaseProduct() async throws {
        try await self.purchaseMonthlyProduct()
    }

    func testCanPurchaseConsumable() async throws {
        let info = try await self.purchaseConsumablePackage().customerInfo

        expect(info.allPurchasedProductIdentifiers).to(contain(Self.consumable10Coins))
    }

    func testCanPurchaseConsumableMultipleTimes() async throws {
        let count = 2

        for _ in 0..<count {
            try await self.purchaseConsumablePackage()
        }

        let info = try await Purchases.shared.customerInfo()
        expect(info.nonSubscriptions).to(haveCount(count))
        expect(info.nonSubscriptions.map(\.productIdentifier)) == Array(repeating: Self.consumable10Coins,
                                                                        count: count)
    }

    func testCanPurchaseConsumableWithMultipleUsers() async throws {
        func verifyPurchase(_ info: CustomerInfo) {
            expect(info.nonSubscriptions).to(haveCount(1))
            expect(info.nonSubscriptions.onlyElement?.productIdentifier) == Self.consumable10Coins
        }

        _ = try await Purchases.shared.logIn("user_1.\(UUID().uuidString)")
        let info1 = try await self.purchaseConsumablePackage().customerInfo
        verifyPurchase(info1)

        let user2 = try await Purchases.shared.logIn("user_1.\(UUID().uuidString)").customerInfo
        expect(user2.nonSubscriptions).to(beEmpty())

        let info2 = try await self.purchaseConsumablePackage().customerInfo
        verifyPurchase(info2)
    }

    func testSubscriptionIsSandbox() async throws {
        let info = try await self.purchaseMonthlyOffering().customerInfo

        let entitlement = try XCTUnwrap(info.entitlements.active.first?.value)

        expect(entitlement.isSandbox) == true
    }

    func testPurchaseUpdatesCustomerInfoDelegate() async throws {
        try await self.purchaseMonthlyOffering()

        let customerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    func testPurchaseFailuresAreReportedCorrectly() async throws {
        self.testSession.failTransactionsEnabled = true
        self.testSession.failureError = .invalidSignature

        do {
            try await self.purchaseMonthlyOffering()
            fail("Expected error")
        } catch {
            expect(error).to(matchError(ErrorCode.invalidPromotionalOfferError))
        }
    }

    func testPurchaseMadeBeforeLogInIsRetainedAfter() async throws {
        try await self.purchaseMonthlyOffering()

        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)_".replacingOccurrences(of: "RCAnonymous", with: "")

        let (identifiedCustomerInfo, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == true
        try await self.verifyEntitlementWentThrough(identifiedCustomerInfo)
    }

    func testPurchaseMadeBeforeLogInWithExistingUserIsNotRetainedUnlessRestoreCalled() async throws {
        let existingUserID = "\(UUID().uuidString)"

        // log in to create the user, then log out
        let (originalCustomerInfo, createdInitialUser) = try await Purchases.shared.logIn(existingUserID)
        self.assertNoPurchases(originalCustomerInfo)
        expect(createdInitialUser) == true

        let anonymousCustomerInfo = try await Purchases.shared.logOut()
        self.assertNoPurchases(anonymousCustomerInfo)

        // purchase as anonymous user, then log in
        try await self.purchaseMonthlyOffering()

        let (customerInfo, created) = try await Purchases.shared.logIn(existingUserID)
        expect(created) == false
        self.assertNoPurchases(customerInfo)

        let restoredCustomerInfo = try await Purchases.shared.restorePurchases()
        try await self.verifyEntitlementWentThrough(restoredCustomerInfo)
    }

    func testPurchaseAsIdentifiedThenLogOutThenRestoreGrantsEntitlements() async throws {
        let existingUserID = UUID().uuidString

        _ = try await Purchases.shared.logIn(existingUserID)
        try await self.purchaseMonthlyOffering()

        var customerInfo = try await Purchases.shared.logOut()
        self.assertNoPurchases(customerInfo)

        customerInfo = try await Purchases.shared.restorePurchases()
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    func testPurchaseWithAskToBuyPostsReceipt() async throws {
        // `SKTestSession` ignores the override done by `Purchases.simulatesAskToBuyInSandbox = true`
        self.testSession.askToBuyEnabled = true

        _ = try await Purchases.shared.logIn(UUID().uuidString)

        do {
            try await self.purchaseMonthlyOffering()
            XCTFail("Expected payment to be deferred")
        } catch ErrorCode.paymentPendingError { /* Expected error */ }

        self.assertNoPurchases(try XCTUnwrap(self.purchasesDelegate.customerInfo))

        let transaction = try XCTUnwrap(self.testSession.allTransactions().onlyElement)

        try self.testSession.approveAskToBuyTransaction(identifier: transaction.identifier)

        let customerInfo = try await Purchases.shared.restorePurchases()
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    func testLogInReturnsCreatedTrueWhenNewAndFalseWhenExisting() async throws {
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        var (_, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == true

        _ = try await Purchases.shared.logOut()

        (_, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == false
    }

    func testLogInThenLogInAsAnotherUserWontTransferPurchases() async throws {
        let userID1 = UUID().uuidString
        let userID2 = UUID().uuidString

        _ = try await Purchases.shared.logIn(userID1)
        try await self.purchaseMonthlyOffering()

        testSession.clearTransactions()

        let (identifiedCustomerInfo, _) = try await Purchases.shared.logIn(userID2)
        self.assertNoPurchases(identifiedCustomerInfo)

        let currentCustomerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)

        expect(currentCustomerInfo.originalAppUserId) == userID2
        self.assertNoPurchases(currentCustomerInfo)
    }

    func testLogOutRemovesEntitlements() async throws {
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        let (_, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == true

        try await self.purchaseMonthlyOffering()

        let loggedOutCustomerInfo = try await Purchases.shared.logOut()
        self.assertNoPurchases(loggedOutCustomerInfo)
    }

    // MARK: - Trial or Intro Eligibility tests

    func testEligibleForIntroBeforePurchase() async throws {
        if Self.storeKit2Setting == .disabled {
            // SK1 implementation relies on the receipt being loaded already.
            // See `TrialOrIntroPriceEligibilityChecker.sk1CheckEligibility`
            _ = try await Purchases.shared.restorePurchases()
        }

        let product = try await self.monthlyPackage.storeProduct

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .eligible
    }

    func testNoIntroOfferIfProductHasNoIntro() async throws {
        let product = try await XCTAsyncUnwrap(await self.monthlyNoIntroProduct)

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .noIntroOfferExists
    }

    func testIneligibleForIntroAfterPurchase() async throws {
        let product = try await self.monthlyPackage.storeProduct

        try await self.purchaseMonthlyOffering()

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .ineligible
    }

    func testEligibleForIntroForDifferentProductAfterPurchase() async throws {
        try await self.purchaseMonthlyOffering()

        let product2 = try await self.annualPackage.storeProduct

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product2)

        expect(eligibility) == .eligible
    }

    func testIneligibleForIntroForDifferentProductInSameSubscriptionGroupAfterPurchase() async throws {
        try XCTSkipIf(
            Self.storeKit2Setting == .enabledForCompatibleDevices,
            "This test currently does not pass with SK2 (see FB11889732)"
        )

        let productWithNoTrial = try await self.product(Self.group3MonthlyNoTrialProductID)
        let productWithTrial = try await self.product(Self.group3MonthlyTrialProductID)

        _ = try await Purchases.shared.purchase(product: productWithNoTrial)

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: productWithTrial)
        expect(eligibility) == .ineligible
    }

    func testEligibleForIntroForDifferentProductInSameSubscriptionGroupAfterExpiration() async throws {
        let productWithNoTrial = try await self.product(Self.group3MonthlyNoTrialProductID)
        let productWithTrial = try await self.annualPackage.storeProduct

        let customerInfo = try await Purchases.shared.purchase(product: productWithNoTrial).customerInfo
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])

        try await self.expireSubscription(entitlement)

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: productWithTrial)
        expect(eligibility) == .eligible
    }

    func testIneligibleForIntroAfterPurchaseExpires() async throws {
        let product = try await self.monthlyPackage.storeProduct

        // 1. Purchase monthly offering
        let customerInfo = try await self.purchaseMonthlyOffering().customerInfo

        // 2. Expire subscription
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])
        try await self.expireSubscription(entitlement)

        // 3. Check eligibility
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .ineligible
    }

    func testEligibleAfterPurchaseWithNoTrialExpires() async throws {
        let productWithNoIntro = try await self.monthlyNoIntroProduct
        let productWithIntro = try await self.monthlyPackage.storeProduct

        let customerInfo = try await Purchases.shared.purchase(product: productWithNoIntro).customerInfo
        let entitlement = try await self.verifyEntitlementWentThrough(customerInfo)

        try await self.expireSubscription(entitlement)

        let info = try await Purchases.shared.syncPurchases()
        self.assertNoActiveSubscription(info)

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: productWithIntro)
        expect(eligibility) == .eligible
    }

    // MARK: -

    func testExpireSubscription() async throws {
        let (_, created) = try await Purchases.shared.logIn(UUID().uuidString)
        expect(created) == true

        var customerInfo = try await self.purchaseMonthlyOffering().customerInfo
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all[Self.entitlementIdentifier])

        try await self.expireSubscription(entitlement)

        customerInfo = try await Purchases.shared.syncPurchases()
        self.assertNoActiveSubscription(customerInfo)
    }

    func testResubscribeAfterExpiration() async throws {
        @discardableResult
        func subscribe() async throws -> CustomerInfo {
            return try await self.purchaseMonthlyOffering().customerInfo
        }

        let (_, created) = try await Purchases.shared.logIn(UUID().uuidString)
        expect(created) == true

        // 1. Subscribe
        let customerInfo = try await subscribe()
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])

        // 2. Expire subscription
        try await self.expireSubscription(entitlement)

        // 3. Resubscribe
        try await subscribe()
    }

    func testUserHasNoEligibleOffersByDefault() async throws {
        let (_, created) = try await Purchases.shared.logIn(UUID().uuidString)
        expect(created) == true

        let offerings = try await Purchases.shared.offerings()
        let product = try XCTUnwrap(offerings.current?.monthly?.storeProduct)
        let discount = try XCTUnwrap(product.discounts.onlyElement)

        expect(discount.offerIdentifier) == "com.revenuecat.monthly_4.99.1_free_week"

        let offers = await product.eligiblePromotionalOffers()
        expect(offers).to(beEmpty())
    }

    @available(iOS 15.2, tvOS 15.2, macOS 12.1, watchOS 8.3, *)
    func testApplyPromotionalOfferDuringSubscription() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let user = UUID().uuidString

        let (_, created) = try await Purchases.shared.logIn(user)
        expect(created) == true

        let product = try await self.monthlyNoIntroProduct

        // 1. Purchase subscription

        var customerInfo = try await Purchases.shared.purchase(product: product).customerInfo

        try await self.verifyEntitlementWentThrough(customerInfo)

        // 2. Get eligible offer

        let offers = await product.eligiblePromotionalOffers()
        expect(offers).to(haveCount(1))
        let offer = try XCTUnwrap(offers.first)

        // 3. Purchase offer

        customerInfo = try await Purchases.shared.purchase(product: product, promotionalOffer: offer).customerInfo

        // 4. Verify purchase went through

        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    @available(iOS 15.2, tvOS 15.2, macOS 12.1, watchOS 8.3, *)
    func testPurchaseWithPromotionalOffer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let user = UUID().uuidString

        let (_, created) = try await Purchases.shared.logIn(user)
        expect(created) == true

        let product = try await self.monthlyNoIntroProduct

        // 1. Purchase subscription

        var customerInfo = try await Purchases.shared.purchase(product: product).customerInfo
        var entitlement = try await self.verifyEntitlementWentThrough(customerInfo)

        // 2. Expire subscription

        try await self.expireSubscription(entitlement)

        let info = try await Purchases.shared.syncPurchases()
        self.assertNoActiveSubscription(info)

        // 3. Get eligible offer

        let offer = try await XCTAsyncUnwrap(await product.eligiblePromotionalOffers().onlyElement)

        // 4. Purchase with offer

        customerInfo = try await Purchases.shared.purchase(product: product, promotionalOffer: offer).customerInfo

        // 5. Verify offer was applied

        entitlement = try await self.verifyEntitlementWentThrough(customerInfo)
        let transaction = try await Self.findTransaction(for: product.productIdentifier)

        expect(entitlement.latestPurchaseDate) != entitlement.originalPurchaseDate
        expect(transaction.offerID) == offer.discount.offerIdentifier
        expect(transaction.offerType) == .promotional
    }

}
