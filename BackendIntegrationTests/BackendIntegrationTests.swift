//
//  BackendIntegrationTests.swift
//  BackendIntegrationTests
//
//  Created by Andrés Boedo on 5/3/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import XCTest
import RevenueCat
import Nimble
import StoreKitTest

class TestPurchaseDelegate: NSObject, PurchasesDelegate {

    var customerInfo: CustomerInfo?
    var customerInfoUpdateCount = 0

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        customerInfoUpdateCount += 1
    }

}

class BackendIntegrationSK2Tests: BackendIntegrationSK1Tests {

    override class var sk2Enabled: Bool { return true }

}

class BackendIntegrationSK1Tests: XCTestCase {

    private var testSession: SKTestSession!
    private var userDefaults: UserDefaults!
    private var purchasesDelegate: TestPurchaseDelegate!

    class var sk2Enabled: Bool { return false }

    private static let timeout: DispatchTimeInterval = .seconds(10)

    override func setUpWithError() throws {
        try super.setUpWithError()

        guard Constants.apiKey != "REVENUECAT_API_KEY", Constants.proxyURL != "REVENUECAT_PROXY_URL" else {
            XCTFail("Must set configuration in `Constants.swift`")
            throw ErrorCode.configurationError
        }

        testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        testSession.resetToDefaultState()
        testSession.disableDialogs = true
        testSession.clearTransactions()

        userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        userDefaults?.removePersistentDomain(forName: Constants.userDefaultsSuiteName)
        if !Constants.proxyURL.isEmpty {
            Purchases.proxyURL = URL(string: Constants.proxyURL)
        }

        configurePurchases()
    }

    func testCanGetOfferings() async throws {
        let receivedOfferings = try await Purchases.shared.offerings()
        expect(receivedOfferings.all).toNot(beEmpty())
    }

    func testCanMakePurchase() async throws {
        try await self.purchaseMonthlyOffering()

        self.verifyEntitlementWentThrough()
        let entitlements = self.purchasesDelegate.customerInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
    }

    func testPurchaseMadeBeforeLogInIsRetainedAfter() async throws {
        let customerInfo = try await self.purchaseMonthlyOffering().customerInfo
        expect(customerInfo.entitlements.all.count) == 1

        let entitlements = self.purchasesDelegate.customerInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true

        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)_".replacingOccurrences(of: "RCAnonymous", with: "")

        let (identifiedCustomerInfo, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == true
        expect(identifiedCustomerInfo.entitlements["premium"]?.isActive) == true
    }

    func testPurchaseMadeBeforeLogInWithExistingUserIsNotRetainedUnlessRestoreCalled() async throws {
        let existingUserID = "\(#function)\(UUID().uuidString)"
        try await self.waitUntilCustomerInfoIsUpdated()

        // log in to create the user, then log out
        _ = try await Purchases.shared.logIn(existingUserID)
        _ = try await Purchases.shared.logOut()

        // purchase as anonymous user, then log in
        try await self.purchaseMonthlyOffering()
        self.verifyEntitlementWentThrough()

        let (customerInfo, created) = try await Purchases.shared.logIn(existingUserID)
        self.assertNoPurchases(customerInfo)
        expect(created) == false

        _ = try await Purchases.shared.restorePurchases()

        self.verifyEntitlementWentThrough()
    }

    func testPurchaseAsIdentifiedThenLogOutThenRestoreGrantsEntitlements() async throws {
        let existingUserID = UUID().uuidString
        try await self.waitUntilCustomerInfoIsUpdated()

        _ = try await Purchases.shared.logIn(existingUserID)
        try await self.purchaseMonthlyOffering()

        self.verifyEntitlementWentThrough()

        let customerInfo = try await Purchases.shared.logOut()
        self.assertNoPurchases(customerInfo)

        _ = try await Purchases.shared.restorePurchases()

        self.verifyEntitlementWentThrough()
    }

    func testPurchaseWithAskToBuyPostsReceipt() async throws {
        try await self.waitUntilCustomerInfoIsUpdated()

        // `SKTestSession` ignores the override done by `Purchases.simulatesAskToBuyInSandbox = true`
        self.testSession.askToBuyEnabled = true

        let customerInfo = try await Purchases.shared.logIn(UUID().uuidString).customerInfo

        do {
            try await self.purchaseMonthlyOffering()
            XCTFail("Expected payment to be deferred")
        } catch ErrorCode.paymentPendingError { /* Expected error */ }

        self.assertNoPurchases(customerInfo)

        let transactions = self.testSession.allTransactions()
        expect(transactions).to(haveCount(1))
        let transaction = transactions.first!

        try self.testSession.approveAskToBuyTransaction(identifier: transaction.identifier)

        // This shouldn't throw error anymore
        try await self.purchaseMonthlyOffering()

        self.verifyEntitlementWentThrough()
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

        self.verifyEntitlementWentThrough()

        testSession.clearTransactions()

        let (identifiedCustomerInfo, _) = try await Purchases.shared.logIn(userID2)
        self.assertNoPurchases(identifiedCustomerInfo)

        expect(self.purchasesDelegate.customerInfo?.originalAppUserId) == userID2
        self.assertNoPurchases(self.purchasesDelegate.customerInfo)
    }

    func testLogOutRemovesEntitlements() async throws {
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        let (_, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == true

        try await self.purchaseMonthlyOffering()

        self.verifyEntitlementWentThrough()

        let loggedOutCustomerInfo = try await Purchases.shared.logOut()
        self.assertNoPurchases(loggedOutCustomerInfo)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testEligibleForIntroBeforePurchaseAndIneligibleAfter() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let offerings = try await Purchases.shared.offerings()
        let productID = try XCTUnwrap(offerings.current?.monthly?.storeProduct.productIdentifier)

        var eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility([productID])
        expect(eligibility[productID]?.status) == .eligible
        
        let customerInfo = try await self.purchaseMonthlyOffering().customerInfo

        expect(customerInfo.entitlements.all.count) == 1
        let entitlements = self.purchasesDelegate.customerInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
            
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)_".replacingOccurrences(of: "RCAnonymous", with: "")

        let (identifiedCustomerInfo, created) = try await Purchases.shared.logIn(identifiedUserID)
        expect(created) == true
        expect(identifiedCustomerInfo.entitlements["premium"]?.isActive) == true

        eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility([productID])
        expect(eligibility[productID]?.status) == .ineligible
    }
    
}

private extension BackendIntegrationSK1Tests {

    @discardableResult
    func purchaseMonthlyOffering() async throws -> PurchaseResultData {
        let offerings = try await Purchases.shared.offerings()
        let monthlyPackage = try XCTUnwrap(offerings.current?.monthly)

        return try await Purchases.shared.purchase(package: monthlyPackage)
    }

    func configurePurchases() {
        purchasesDelegate = TestPurchaseDelegate()
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults,
                            useStoreKit2IfAvailable: Self.sk2Enabled)
        Purchases.logLevel = .debug
        Purchases.shared.delegate = purchasesDelegate
    }

    func verifyEntitlementWentThrough() {
        expect(self.purchasesDelegate.customerInfo?.entitlements.all.count) == 1
    }

    func assertNoPurchases(_ customerInfo: CustomerInfo?) {
        expect(customerInfo?.entitlements.all).to(beEmpty())
    }

    @discardableResult
    func waitUntilCustomerInfoIsUpdated() async throws -> CustomerInfo {
        let customerInfo = try await Purchases.shared.customerInfo()
        expect(self.purchasesDelegate.customerInfoUpdateCount) == 1

        return customerInfo
    }

}
