//
//  StoreKitIntegrationTests.swift
//  StoreKitIntegrationTests
//
//  Created by Andrés Boedo on 5/3/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

// swiftlint:disable file_length

class StoreKit2IntegrationTests: StoreKit1IntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

}

class StoreKit1IntegrationTests: BaseBackendIntegrationTests {

    private var testSession: SKTestSession!

    override func setUp() async throws {
        try await super.setUp()

        self.testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true
        self.testSession.clearTransactions()
        if #available(iOS 15.2, *) {
            self.testSession.timeRate = .monthlyRenewalEveryThirtySeconds
        } else {
            self.testSession.timeRate = .oneSecondIsOneDay
        }

        // SDK initialization begins with an initial request to offerings
        // Which results in a get-create of the initial anonymous user.
        // To avoid race conditions with when this request finishes and make all tests deterministic
        // this waits for that request to finish.
        _ = try await Purchases.shared.offerings()
    }

    override class var storeKit2Setting: StoreKit2Setting {
        return .disabled
    }

    func testIsSandbox() {
        expect(Purchases.shared.isSandbox) == true
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

    func testSubscriptionIsSandbox() async throws {
        let info = try await self.purchaseMonthlyOffering().customerInfo

        let entitlement = try XCTUnwrap(info.entitlements.active.first?.value)

        expect(entitlement.isSandbox) == true
    }

    func testPurchaseUpdatesCustomerInfoDelegate() async throws {
        try await self.purchaseMonthlyOffering()

        let customerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)
        try self.verifyEntitlementWentThrough(customerInfo)
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
        try verifyEntitlementWentThrough(identifiedCustomerInfo)
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
        try self.verifyEntitlementWentThrough(restoredCustomerInfo)
    }

    func testPurchaseAsIdentifiedThenLogOutThenRestoreGrantsEntitlements() async throws {
        let existingUserID = UUID().uuidString

        _ = try await Purchases.shared.logIn(existingUserID)
        try await self.purchaseMonthlyOffering()

        var customerInfo = try await Purchases.shared.logOut()
        self.assertNoPurchases(customerInfo)

        customerInfo = try await Purchases.shared.restorePurchases()
        try self.verifyEntitlementWentThrough(customerInfo)
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

        // This shouldn't throw error anymore
        try await self.purchaseMonthlyOffering()
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
        let product = try await XCTAsyncUnwrap(
            await Purchases.shared.products(["com.revenuecat.weekly_1.99.no_intro"]).onlyElement
        )

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

    func testIneligibleForIntroAfterPurchaseExpires() async throws {
        let product = try await self.weeklyPackage.storeProduct

        let customerInfo = try await self.purchaseWeeklyOffering().customerInfo
        let entitlement = try self.verifyEntitlementWentThrough(customerInfo)

        try await self.expireSubscription(entitlement)

        let info = try await Purchases.shared.syncPurchases()

        self.assertNoActiveSubscription(info)

        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .ineligible
    }

    func testEligibleAfterPurchaseWithNoTrialExpires() async throws {
        let products = await Purchases.shared.products(["com.revenuecat.weekly_1.99.no_intro"])
        let productWithNoIntro = try XCTUnwrap(products.first)
        let productWithIntro = try await self.weeklyPackage.storeProduct

        let customerInfo = try await Purchases.shared.purchase(product: productWithNoIntro).customerInfo
        let entitlement = try self.verifyEntitlementWentThrough(customerInfo)

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

        try await self.purchaseWeeklyOffering()
        var customerInfo = try await Purchases.shared.syncPurchases()

        let entitlement = try self.verifyEntitlementWentThrough(customerInfo)
        try await self.expireSubscription(entitlement)

        customerInfo = try await Purchases.shared.syncPurchases()
        self.assertNoActiveSubscription(customerInfo)
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
    func testPurchaseWithPromotionalOffer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        try XCTSkipIf(Self.storeKit2Setting == .enabledForCompatibleDevices,
                      "This test is not currently passing on SK2")

        let user = UUID().uuidString

        let (_, created) = try await Purchases.shared.logIn(user)
        expect(created) == true

        let products = await Purchases.shared.products(["com.revenuecat.weekly_1.99.no_intro"])
        let product = try XCTUnwrap(products.first)

        // 1. Purchase subscription

        _ = try await Purchases.shared.purchase(product: product)
        var customerInfo = try await Purchases.shared.syncPurchases()

        var entitlement = try self.verifyEntitlementWentThrough(customerInfo)

        // 2. Expire subscription

        try await self.expireSubscription(entitlement)

        let info = try await Purchases.shared.syncPurchases()
        self.assertNoActiveSubscription(info)

        // 3. Get eligible offer

        let offer = try await XCTAsyncUnwrap(await product.eligiblePromotionalOffers().onlyElement)

        // 4. Purchase with offer

        _ = try await Purchases.shared.purchase(product: product, promotionalOffer: offer)
        customerInfo = try await Purchases.shared.syncPurchases()

        // 5. Verify offer was applied

        entitlement = try self.verifyEntitlementWentThrough(customerInfo)

        let transactions: [Transaction] = await Transaction
            .currentEntitlements
            .compactMap {
                switch $0 {
                case let .verified(transaction): return transaction
                case .unverified: return nil
                }
            }
            .filter { $0.productID == product.productIdentifier }
            .extractValues()

        let transaction = try XCTUnwrap(transactions.onlyElement)

        expect(entitlement.latestPurchaseDate) != entitlement.originalPurchaseDate
        expect(transaction.offerID) == offer.discount.offerIdentifier
        expect(transaction.offerType) == .promotional
    }

}

private extension StoreKit1IntegrationTests {

    static let entitlementIdentifier = "premium"

    private var currentOffering: Offering {
        get async throws {
            return try await XCTAsyncUnwrap(try await Purchases.shared.offerings().current)
        }
    }

    var weeklyPackage: Package {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.currentOffering.weekly)
        }
    }

    var monthlyPackage: Package {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.currentOffering.monthly)
        }
    }

    var annualPackage: Package {
        get async throws {
            return try await XCTAsyncUnwrap(try await self.currentOffering.annual)
        }
    }

    @discardableResult
    func purchaseMonthlyOffering(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let data = try await Purchases.shared.purchase(package: self.monthlyPackage)

        try self.verifyEntitlementWentThrough(data.customerInfo,
                                              file: file,
                                              line: line)

        return data
    }

    @discardableResult
    func purchaseMonthlyProduct(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let data = try await Purchases.shared.purchase(product: self.monthlyPackage.storeProduct)

        try self.verifyEntitlementWentThrough(data.customerInfo,
                                              file: file,
                                              line: line)

        return data
    }

    @discardableResult
    func purchaseWeeklyOffering(
        file: FileString = #file,
        line: UInt = #line
    ) async throws -> PurchaseResultData {
        let data = try await Purchases.shared.purchase(package: self.weeklyPackage)

        try self.verifyEntitlementWentThrough(data.customerInfo,
                                              file: file,
                                              line: line)

        return data
    }

    @discardableResult
    func verifyEntitlementWentThrough(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) throws -> EntitlementInfo {
        let entitlements = customerInfo.entitlements.all

        expect(
            file: file, line: line,
            entitlements
        ).to(
            haveCount(1),
            description: "Expected Entitlement. Got: \(entitlements)"
        )

        return try XCTUnwrap(entitlements[Self.entitlementIdentifier])
    }

    func assertNoActiveSubscription(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            customerInfo.entitlements.active
        ).to(
            beEmpty(),
            description: "Expected no active entitlements"
        )
    }

    func assertNoPurchases(
        _ customerInfo: CustomerInfo,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            customerInfo.entitlements.all
        )
        .to(
            beEmpty(),
            description: "Expected no entitlements. Got: \(customerInfo.entitlements.all)"
        )
    }

    func expireSubscription(_ entitlement: EntitlementInfo) async throws {
        guard let expirationDate = entitlement.expirationDate else { return }

        Logger.info("Expiring subscription for product '\(entitlement.productIdentifier)'")

        // Try expiring using `SKTestSession`
        do {
            try self.testSession.expireSubscription(productIdentifier: entitlement.productIdentifier)
        } catch {
            Logger.warn(
                """
                Failed testSession.expireSubscription, this is probably an Xcode bug.
                Test will now wait for expiration instead of triggering it.
                Error: \(error.localizedDescription)
                """
            )
        }

        let secondsUntilExpiration = expirationDate.timeIntervalSince(Date())
        guard secondsUntilExpiration > 0 else {
            Logger.info("Done waiting for subscription expiration, continuing test.")
            return
        }

        let timeToSleep = Int(secondsUntilExpiration.rounded(.up) + 1)

        // `SKTestSession.expireSubscription` doesn't seem to work, so force expiration by waiting
        Logger.warn("Sleeping for \(timeToSleep) seconds to force expiration")
        try await Task.sleep(nanoseconds: UInt64(timeToSleep * 1_000_000_000))
    }

}

extension AsyncSequence {

    func extractValues() async rethrows -> [Element] {
        return try await self.reduce(into: [Element]()) {
            $0 += [$1]
        }
    }

}
