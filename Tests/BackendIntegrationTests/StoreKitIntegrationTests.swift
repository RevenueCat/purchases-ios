//
//  StoreKitIntegrationTests.swift
//  StoreKitIntegrationTests
//
//  Created by Andrés Boedo on 5/3/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Nimble
@testable import RevenueCat
import SnapshotTesting
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

    func testIsSandbox() throws {
        try expect(self.purchases.isSandbox) == true
    }

    func testPurchasesDiagnostics() async throws {
        let diagnostics = PurchasesDiagnostics(purchases: try self.purchases)

        try await diagnostics.testSDKHealth()
    }

    func testCanGetOfferings() async throws {
        self.logger.clearMessages()

        let receivedOfferings = try await self.purchases.offerings()

        expect(receivedOfferings.all).toNot(beEmpty())
        assertSnapshot(matching: receivedOfferings.response, as: .formattedJson)

        self.logger.verifyMessageWasLogged(Strings.offering.vending_offerings_cache_from_memory,
                                           level: .debug)
    }

    func testCanPurchasePackage() async throws {
        let package = try await self.monthlyPackage
        let transaction = try await XCTAsyncUnwrap(try await self.purchaseMonthlyOffering().transaction)

        self.logger.verifyMessageWasLogged(
            Strings.purchase.transaction_poster_handling_transaction(
                transactionID: transaction.transactionIdentifier,
                productID: package.storeProduct.productIdentifier,
                transactionDate: transaction.purchaseDate,
                offeringID: package.offeringIdentifier,
                paywallSessionID: nil
            )
        )
    }

    func testCanPurchaseProduct() async throws {
        try await self.purchaseMonthlyProduct()
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testPurchasingSK1ProductDoesNotLeaveUnfinishedSK2Transaction() async throws {
        try XCTSkipIf(Self.storeKit2Setting.usesStoreKit2IfAvailable, "Test only for SK1")

        func verifyNoUnfinishedTransactions() async {
            let unfinishedTransactions = await Transaction.unfinished.extractValues()
            expect(unfinishedTransactions).to(beEmpty())
        }

        await verifyNoUnfinishedTransactions()
        try await self.purchaseMonthlyProduct()
        await verifyNoUnfinishedTransactions()
    }

    func testPurchasingPackageWithPresentedOfferingIdentifier() async throws {
        let package = try await self.monthlyPackage

        try self.purchases.cachePresentedOfferingIdentifier(
            package.offeringIdentifier,
            productIdentifier: package.storeProduct.productIdentifier
        )

        let transaction = try await XCTAsyncUnwrap(try await self.purchaseMonthlyProduct().transaction)

        self.logger.verifyMessageWasLogged(
            Strings.purchase.transaction_poster_handling_transaction(
                transactionID: transaction.transactionIdentifier,
                productID: package.storeProduct.productIdentifier,
                transactionDate: transaction.purchaseDate,
                offeringID: package.offeringIdentifier,
                paywallSessionID: nil
            )
        )
    }

    func testCanPurchaseConsumable() async throws {
        let result = try await self.purchaseConsumablePackage()
        let info = result.customerInfo
        let transaction = try XCTUnwrap(result.transaction)
        let nonSubscription = try XCTUnwrap(info.nonSubscriptions.onlyElement)

        expect(nonSubscription.productIdentifier) == Self.consumable10Coins
        expect(nonSubscription.storeTransactionIdentifier) == transaction.transactionIdentifier
        expect(info.allPurchasedProductIdentifiers).to(contain(Self.consumable10Coins))

        self.verifyTransactionWasFinished()
    }

    func testCanPurchaseConsumableMultipleTimes() async throws {
        let count = 2

        for _ in 0..<count {
            try await self.purchaseConsumablePackage()
        }

        let info = try await self.purchases.customerInfo()
        expect(info.nonSubscriptions).to(haveCount(count))
        expect(info.nonSubscriptions.map(\.productIdentifier)) == Array(repeating: Self.consumable10Coins,
                                                                        count: count)

        self.verifyTransactionWasFinished(count: count)
    }

    func testCanPurchaseConsumableWithMultipleUsers() async throws {
        func verifyPurchase(_ info: CustomerInfo) {
            expect(info.nonSubscriptions).to(haveCount(1))
            expect(info.nonSubscriptions.onlyElement?.productIdentifier) == Self.consumable10Coins
        }

        _ = try await self.purchases.logIn("user_1.\(UUID().uuidString)")
        let info1 = try await self.purchaseConsumablePackage().customerInfo
        verifyPurchase(info1)

        let user2 = try await self.purchases.logIn("user_1.\(UUID().uuidString)").customerInfo
        expect(user2.nonSubscriptions).to(beEmpty())

        let info2 = try await self.purchaseConsumablePackage().customerInfo
        verifyPurchase(info2)

        self.verifyTransactionWasFinished(count: 2)
    }

    func testCanPurchaseNonConsumable() async throws {
        let result = try await self.purchaseNonConsumablePackage()
        let transaction = try XCTUnwrap(result.transaction)
        let info = result.customerInfo
        let nonSubscription = try XCTUnwrap(info.nonSubscriptions.onlyElement)

        expect(info.allPurchasedProductIdentifiers).to(contain(Self.nonConsumableLifetime))
        expect(nonSubscription.productIdentifier) == transaction.productIdentifier
        expect(nonSubscription.storeTransactionIdentifier) == transaction.transactionIdentifier

        try await self.verifyEntitlementWentThrough(info)

        self.verifyTransactionWasFinished()
    }

    func testCanPurchaseNonRenewingSubscription() async throws {
        let result = try await self.purchaseNonRenewingSubscriptionPackage()
        let transaction = try XCTUnwrap(result.transaction)
        let info = result.customerInfo
        let nonSubscription = try XCTUnwrap(info.nonSubscriptions.onlyElement)

        expect(info.allPurchasedProductIdentifiers).to(contain(transaction.productIdentifier))
        expect(nonSubscription.productIdentifier) == transaction.productIdentifier
        expect(nonSubscription.storeTransactionIdentifier) == transaction.transactionIdentifier

        try await self.verifyEntitlementWentThrough(info)

        self.verifyTransactionWasFinished()
    }

    func testCanPurchaseMultipleSubscriptions() async throws {
        let product1 = try await self.monthlyPackage.storeProduct
        let product2 = try await self.annualPackage.storeProduct

        _ = try await self.purchases.purchase(product: product1)
        let info = try await self.purchases.purchase(product: product2).customerInfo

        try await self.verifyEntitlementWentThrough(info)

        expect(info.allPurchasedProductIdentifiers) == [
            product1.productIdentifier,
            product2.productIdentifier
        ]
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

    #if swift(>=5.9)
    @available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
    func testPurchaseCancellationsAreReportedCorrectly() async throws {
        try AvailabilityChecks.iOS17APIAvailableOrSkipTest()

        try await self.testSession.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)

        let (_, info, cancelled) = try await self.purchases.purchase(package: self.monthlyPackage)
        expect(info.entitlements.active).to(beEmpty())
        expect(cancelled) == true
    }
    #endif

    func testPurchaseMadeBeforeLogInIsRetainedAfter() async throws {
        try await self.purchaseMonthlyOffering()

        let anonUserID = try self.purchases.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)_".replacingOccurrences(of: "RCAnonymous", with: "")

        let (identifiedCustomerInfo, created) = try await self.purchases.logIn(identifiedUserID)
        expect(created) == true
        try await self.verifyEntitlementWentThrough(identifiedCustomerInfo)
    }

    func testPurchaseMadeBeforeLogInWithExistingUserIsNotRetainedUnlessRestoreCalled() async throws {
        let existingUserID = "\(UUID().uuidString)"

        // log in to create the user, then log out
        let (originalCustomerInfo, createdInitialUser) = try await self.purchases.logIn(existingUserID)
        self.assertNoPurchases(originalCustomerInfo)
        expect(createdInitialUser) == true

        let anonymousCustomerInfo = try await self.purchases.logOut()
        self.assertNoPurchases(anonymousCustomerInfo)

        // purchase as anonymous user, then log in
        try await self.purchaseMonthlyOffering()

        let (customerInfo, created) = try await self.purchases.logIn(existingUserID)
        expect(created) == false
        self.assertNoPurchases(customerInfo)

        let restoredCustomerInfo = try await self.purchases.restorePurchases()
        try await self.verifyEntitlementWentThrough(restoredCustomerInfo)
    }

    func testPurchaseAsIdentifiedThenLogOutThenRestoreGrantsEntitlements() async throws {
        let existingUserID = UUID().uuidString

        _ = try await self.purchases.logIn(existingUserID)
        try await self.purchaseMonthlyOffering()

        var customerInfo = try await self.purchases.logOut()
        self.assertNoPurchases(customerInfo)

        customerInfo = try await self.purchases.restorePurchases()
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    func testPurchaseWithAskToBuyPostsReceipt() async throws {
        // `SKTestSession` ignores the override done by `Purchases.simulatesAskToBuyInSandbox = true`
        self.testSession.askToBuyEnabled = true

        _ = try await self.purchases.logIn(UUID().uuidString)

        do {
            try await self.purchaseMonthlyOffering()
            XCTFail("Expected payment to be deferred")
        } catch ErrorCode.paymentPendingError { /* Expected error */ }

        self.assertNoPurchases(try XCTUnwrap(self.purchasesDelegate.customerInfo))

        let transaction = try XCTUnwrap(self.testSession.allTransactions().onlyElement)

        try self.testSession.approveAskToBuyTransaction(identifier: transaction.identifier)

        let customerInfo = try await self.purchases.restorePurchases()
        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    func testLogInReturnsCreatedTrueWhenNewAndFalseWhenExisting() async throws {
        let anonUserID = try self.purchases.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        var (_, created) = try await self.purchases.logIn(identifiedUserID)
        expect(created) == true

        _ = try await self.purchases.logOut()

        (_, created) = try await self.purchases.logIn(identifiedUserID)
        expect(created) == false
    }

    func testLogInThenLogInAsAnotherUserWontTransferPurchases() async throws {
        let userID1 = UUID().uuidString
        let userID2 = UUID().uuidString

        _ = try await self.purchases.logIn(userID1)
        try await self.purchaseMonthlyOffering()

        testSession.clearTransactions()

        let (identifiedCustomerInfo, _) = try await self.purchases.logIn(userID2)
        self.assertNoPurchases(identifiedCustomerInfo)

        let currentCustomerInfo = try XCTUnwrap(self.purchasesDelegate.customerInfo)

        expect(currentCustomerInfo.originalAppUserId) == userID2
        self.assertNoPurchases(currentCustomerInfo)
    }

    func testRenewalsOnASeparateUserDontTransferPurchases() async throws {
        let prefix = UUID().uuidString
        let userID1 = "\(prefix)-user-1"
        let userID2 = "\(prefix)-user-2"

        let anonymousUser = try self.purchases.appUserID
        let productIdentifier = try await self.monthlyPackage.storeProduct.productIdentifier

        // 1. Purchase with user 1
        let user1CustomerInfo = try await self.purchases.logIn(userID1).customerInfo
        self.assertNoPurchases(user1CustomerInfo)
        expect(user1CustomerInfo.originalAppUserId) == anonymousUser
        try await self.purchaseMonthlyOffering()

        // 2. Change to user 2
        let (identifiedCustomerInfo, _) = try await self.purchases.logIn(userID2)
        self.assertNoPurchases(identifiedCustomerInfo)

        // 3. Renew subscription
        self.logger.clearMessages()

        try self.testSession.forceRenewalOfSubscription(productIdentifier: productIdentifier)

        try await self.verifyReceiptIsEventuallyPosted()

        // 4. Verify new user does not have entitlement
        let currentCustomerInfo = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(currentCustomerInfo.originalAppUserId) == userID2
        self.assertNoPurchases(currentCustomerInfo)
    }

    func testUserCanMakePurchaseAfterTransferBlocked() async throws {
        let prefix = UUID().uuidString
        let userID1 = "\(prefix)-user-1"
        let userID2 = "\(prefix)-user-2"

        let anonymousUser = try self.purchases.appUserID
        let productIdentifier = try await self.monthlyPackage.storeProduct.productIdentifier

        // 1. Purchase with user 1
        var user1CustomerInfo = try await self.purchases.logIn(userID1).customerInfo
        self.assertNoPurchases(user1CustomerInfo)
        expect(user1CustomerInfo.originalAppUserId) == anonymousUser
        try await self.purchaseMonthlyOffering()

        // 2. Change to user 2
        let (identifiedCustomerInfo, _) = try await self.purchases.logIn(userID2)
        self.assertNoPurchases(identifiedCustomerInfo)

        // 3. Renew subscription
        self.logger.clearMessages()

        try self.testSession.forceRenewalOfSubscription(productIdentifier: productIdentifier)

        try await self.verifyReceiptIsEventuallyPosted()

        // 4. Verify new user does not have entitlement
        var currentCustomerInfo = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(currentCustomerInfo.originalAppUserId) == userID2
        self.assertNoPurchases(currentCustomerInfo)

        // 5. Make purchase with user 2
        self.logger.clearMessages()
        currentCustomerInfo = try await self.purchaseMonthlyOffering().customerInfo
        try await self.verifyReceiptIsEventuallyPosted()

        // 6. Verify user 2 has purchases
        expect(currentCustomerInfo.originalAppUserId) == userID2
        expect(currentCustomerInfo.entitlements.all).toNot(beEmpty())

        // 7. Verify that user 1 does not have purchases because they were transferred to user 2
        user1CustomerInfo = try await self.purchases.logIn(userID1).customerInfo
        self.assertNoPurchases(user1CustomerInfo)
    }

    func testPurchaseAfterSigningIntoNewUser() async throws {
        let prefix = UUID().uuidString
        let userID1 = "\(prefix)-user-1"
        let userID2 = "\(prefix)-user-2"

        let anonymousUser = try self.purchases.appUserID

        // 1. Purchase with user 1
        let user1CustomerInfo = try await self.purchases.logIn(userID1).customerInfo
        expect(user1CustomerInfo.originalAppUserId) == anonymousUser
        try await self.purchaseMonthlyOffering()

        // 2. Change to user 2
        let (identifiedCustomerInfo, _) = try await self.purchases.logIn(userID2)
        self.assertNoPurchases(identifiedCustomerInfo)

        // 3. Purchase again and verify user gets entitlement
        let newCustomerInfo = try await self.purchaseMonthlyOffering().customerInfo
        expect(newCustomerInfo.originalAppUserId) == userID2
    }

    func testLogOutRemovesEntitlements() async throws {
        let anonUserID = try self.purchases.appUserID
        let identifiedUserID = "identified_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        let (_, created) = try await self.purchases.logIn(identifiedUserID)
        expect(created) == true

        try await self.purchaseMonthlyOffering()

        let loggedOutCustomerInfo = try await self.purchases.logOut()
        self.assertNoPurchases(loggedOutCustomerInfo)
    }

    // MARK: - Trial or Intro Eligibility tests

    func testTrialEligibilityMakesNoNetworkRequests() async throws {
        try await self.verifyReceiptIsPresentBeforeEligibilityChecking()

        let product = try await self.monthlyPackage.storeProduct

        self.logger.clearMessages()

        _ = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: product)

        self.logger.verifyMessageWasNotLogged("API request started")
    }

    func testEligibleForIntroBeforePurchase() async throws {
        try await self.verifyReceiptIsPresentBeforeEligibilityChecking()

        let product = try await self.monthlyPackage.storeProduct

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .eligible
    }

    func testNoIntroOfferIfProductHasNoIntro() async throws {
        let product = try await XCTAsyncUnwrap(await self.monthlyNoIntroProduct)

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .noIntroOfferExists
    }

    func testIneligibleForIntroAfterPurchase() async throws {
        let product = try await self.monthlyPackage.storeProduct

        try await self.purchaseMonthlyOffering()

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .ineligible
    }

    func testEligibleForIntroForDifferentProductAfterPurchase() async throws {
        try await self.purchaseMonthlyOffering()

        let product2 = try await self.annualPackage.storeProduct

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: product2)

        expect(eligibility) == .eligible
    }

    func testIneligibleForIntroForDifferentProductInSameSubscriptionGroupAfterPurchase() async throws {
        if Self.storeKit2Setting == .enabledForCompatibleDevices {
            XCTExpectFailure("This test currently does not pass with SK2 (see FB11889732)")
        }

        let productWithNoTrial = try await self.product(Self.group3MonthlyNoTrialProductID)
        let productWithTrial = try await self.product(Self.group3MonthlyTrialProductID)

        _ = try await self.purchases.purchase(product: productWithNoTrial)

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: productWithTrial)
        expect(eligibility) == .ineligible
    }

    func testEligibleForIntroForDifferentProductInSameSubscriptionGroupAfterExpiration() async throws {
        let productWithNoTrial = try await self.product(Self.group3MonthlyNoTrialProductID)
        let productWithTrial = try await self.annualPackage.storeProduct

        let customerInfo = try await self.purchases.purchase(product: productWithNoTrial).customerInfo
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])

        try await self.expireSubscription(entitlement)

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: productWithTrial)
        expect(eligibility) == .eligible
    }

    func testIneligibleForIntroForDifferentProductInSameSubscriptionGroupAfterTrialExpiration() async throws {
        let monthlyWithTrial = try await self.product(Self.group3YearlyTrialProductID)
        let annualWithTrial = try await self.product(Self.group3MonthlyTrialProductID)

        let customerInfo = try await self.purchases.purchase(product: monthlyWithTrial).customerInfo
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])
        try await self.expireSubscription(entitlement)

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: annualWithTrial)
        expect(eligibility) == .ineligible
    }

    func testIneligibleForIntroAfterPurchaseExpires() async throws {
        let product = try await self.monthlyPackage.storeProduct

        // 1. Purchase monthly offering
        let customerInfo = try await self.purchaseMonthlyOffering().customerInfo

        // 2. Expire subscription
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])
        try await self.expireSubscription(entitlement)

        // 3. Check eligibility
        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: product)
        expect(eligibility) == .ineligible
    }

    func testEligibleAfterPurchaseWithNoTrialExpires() async throws {
        let productWithNoIntro = try await self.monthlyNoIntroProduct
        let productWithIntro = try await self.monthlyPackage.storeProduct

        let customerInfo = try await self.purchases.purchase(product: productWithNoIntro).customerInfo
        let entitlement = try await self.verifyEntitlementWentThrough(customerInfo)

        try await self.expireSubscription(entitlement)
        try await self.verifySubscriptionExpired()

        let eligibility = try await self.purchases.checkTrialOrIntroDiscountEligibility(product: productWithIntro)
        expect(eligibility) == .eligible
    }

    // MARK: -

    func testExpireSubscription() async throws {
        let (_, created) = try await self.purchases.logIn(UUID().uuidString)
        expect(created) == true

        let customerInfo = try await self.purchaseMonthlyOffering().customerInfo
        let entitlement = try XCTUnwrap(customerInfo.entitlements.all[Self.entitlementIdentifier])

        try await self.expireSubscription(entitlement)
        try await self.verifySubscriptionExpired()
    }

    func testResubscribeAfterExpiration() async throws {
        @discardableResult
        func subscribe() async throws -> CustomerInfo {
            return try await self.purchaseMonthlyOffering().customerInfo
        }

        let (_, created) = try await self.purchases.logIn(UUID().uuidString)
        expect(created) == true

        // 1. Subscribe
        let customerInfo = try await subscribe()
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])

        // 2. Expire subscription
        try await self.expireSubscription(entitlement)

        // 3. Resubscribe
        try await subscribe()
    }

    func testSubscribeAfterExpirationWhileAppIsClosed() async throws {
        func waitForNewPurchaseDate() async {
            // The backend uses the transaction purchase date as a way to disambiguate transactions.
            // Therefor we need to sleep to force these to have unique dates.
            try? await Task.sleep(nanoseconds: DispatchTimeInterval.seconds(2).nanoseconds)
        }

        // 1. Subscribe
        let customerInfo = try await self.purchaseMonthlyOffering().customerInfo
        let entitlement = try XCTUnwrap(customerInfo.entitlements[Self.entitlementIdentifier])

        // 2. Simulate closing app
        Purchases.clearSingleton()

        // 3. Force several renewals while app is closed.
        for _ in 0..<3 {
            await waitForNewPurchaseDate()
            try self.testSession.forceRenewalOfSubscription(productIdentifier: entitlement.productIdentifier)
        }

        await waitForNewPurchaseDate()

        // 4. Expire subscription
        try await self.expireSubscription(entitlement)

        // 5. Re-open app
        await self.resetSingleton()

        // 6. Wait for pending transactions to be posted
        try await self.waitUntilNoUnfinishedTransactions()

        // 7. Purchase again
        self.logger.clearMessages()
        try await self.purchaseMonthlyProduct()

        // 8. Verify transaction is posted as a purchase.
        self.logger.verifyMessageWasLogged("Posting receipt (source: 'purchase')")
    }

    func testGetPromotionalOfferWithNoPurchasesReturnsIneligible() async throws {
        let product = try await self.monthlyPackage.storeProduct
        let discount = try XCTUnwrap(product.discounts.onlyElement)
        self.logger.clearMessages()

        do {
            _ = try await self.purchases.promotionalOffer(forProductDiscount: discount, product: product)
        } catch {
            expect(error).to(matchError(ErrorCode.ineligibleError))
        }
        self.logger.verifyMessageWasNotLogged("API request started")
    }

    func testUserHasNoEligibleOffersByDefault() async throws {
        let (_, created) = try await self.purchases.logIn(UUID().uuidString)
        expect(created) == true

        let offerings = try await self.purchases.offerings()
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

        let (_, created) = try await self.purchases.logIn(user)
        expect(created) == true

        let product = try await self.monthlyNoIntroProduct

        // 1. Purchase subscription

        var customerInfo = try await self.purchases.purchase(product: product).customerInfo

        try await self.verifyEntitlementWentThrough(customerInfo)

        // 2. Get eligible offer

        let offers = await product.eligiblePromotionalOffers()
        expect(offers).to(haveCount(1))
        let offer = try XCTUnwrap(offers.first)

        // 3. Purchase offer

        customerInfo = try await self.purchases.purchase(product: product, promotionalOffer: offer).customerInfo

        // 4. Verify purchase went through

        try await self.verifyEntitlementWentThrough(customerInfo)
    }

    @available(iOS 15.2, tvOS 15.2, macOS 12.1, watchOS 8.3, *)
    func testPurchaseWithPromotionalOffer() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let user = UUID().uuidString

        let (_, created) = try await self.purchases.logIn(user)
        expect(created) == true

        let product = try await self.monthlyNoIntroProduct

        // 1. Purchase subscription

        var customerInfo = try await self.purchases.purchase(product: product).customerInfo
        var entitlement = try await self.verifyEntitlementWentThrough(customerInfo)

        // 2. Expire subscription

        try await self.expireSubscription(entitlement)
        try await self.verifySubscriptionExpired()

        // 3. Get eligible offer

        let offer = try await XCTAsyncUnwrap(await product.eligiblePromotionalOffers().onlyElement)

        // 4. Purchase with offer

        customerInfo = try await self.purchases.purchase(product: product, promotionalOffer: offer).customerInfo

        // 5. Verify offer was applied

        entitlement = try await self.verifyEntitlementWentThrough(customerInfo)
        let transaction = try await Self.findTransaction(for: product.productIdentifier)

        expect(entitlement.latestPurchaseDate) != entitlement.originalPurchaseDate
        expect(transaction.offerID) == offer.discount.offerIdentifier
        expect(transaction.offerType) == .promotional
    }

    func testCustomerInfoStream() async throws {
        let purchases = try self.purchases
        let updates: Atomic<[CustomerInfo]> = .init([])

        let task = Task {
            for await info in purchases.customerInfoStream {
                updates.modify { $0.append(info) }
            }
        }
        defer { task.cancel() }

        try await asyncWait(timeout: .seconds(1)) {
            "Expected only one value initially: \($0 ?? [])"
        } until: {
            updates.value
        } condition: {
            $0.count == 1
        }

        let info = try await self.purchaseMonthlyProduct().customerInfo

        expect(updates.value).to(haveCount(2))
        expect(updates.value.last) === info
    }

    func testSandboxXcodePurchasesDoNotGrantProductionEntitlements() async throws {
        // 1. Purchase subscription
        try await self.purchaseMonthlyProduct()

        // 2. Relaunch in "production" mode
        Self.isSandbox = false
        await self.resetSingleton()

        // 3. Verify no subscriptions are active
        let customerInfo = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        self.assertNoActiveSubscription(customerInfo)
    }

}

private extension BaseStoreKitIntegrationTests {

    func verifyReceiptIsPresentBeforeEligibilityChecking() async throws {
        if Self.storeKit2Setting == .disabled {
            // SK1 implementation relies on the receipt being loaded already.
            // See `TrialOrIntroPriceEligibilityChecker.sk1CheckEligibility`
            _ = try await self.purchases.restorePurchases()
        }
    }

}
