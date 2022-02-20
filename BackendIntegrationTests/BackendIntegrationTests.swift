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

    func purchases(_ purchases: Purchases,
                   shouldPurchasePromoProduct product: StoreProduct,
                   defermentBlock makeDeferredPurchase: @escaping DeferredPromotionalPurchaseBlock) {
    }
}

class BackendIntegrationTests: XCTestCase {

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!
    var purchasesDelegate: TestPurchaseDelegate!

    private static let timeout: DispatchTimeInterval = .seconds(10)

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        testSession.disableDialogs = true
        testSession.clearTransactions()

        userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        userDefaults?.removePersistentDomain(forName: Constants.userDefaultsSuiteName)
        if !Constants.proxyURL.isEmpty {
            Purchases.proxyURL = URL(string: Constants.proxyURL)
        }

        configurePurchases()
    }

    func testCanGetOfferings() throws {
        var completionCalled = false
        var receivedError: Error? = nil
        var receivedOfferings: Offerings? = nil
        Purchases.shared.getOfferings { offerings, error in
            completionCalled = true
            receivedError = error
            receivedOfferings = offerings
        }
        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)

        expect(receivedError).to(beNil())
        let unwrappedOfferings = try XCTUnwrap(receivedOfferings)
        expect(unwrappedOfferings.all).toNot(beEmpty())
    }

    func testCanMakePurchase() throws {
        purchaseMonthlyOffering()

        waitUntilEntitlementsGoThrough()
        let entitlements = purchasesDelegate.customerInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
    }

    func testPurchaseMadeBeforeLogInIsRetainedAfter() {
        var completionCalled = false
        purchaseMonthlyOffering { [self] customerInfo, error in
            expect(customerInfo?.entitlements.all.count) == 1
            let entitlements = self.purchasesDelegate.customerInfo?.entitlements
            expect(entitlements?["premium"]?.isActive) == true

            let anonUserID = Purchases.shared.appUserID
            let identifiedUserID = "\(#function)_\(anonUserID)_".replacingOccurrences(of: "RCAnonymous", with: "")

            Purchases.shared.logIn(identifiedUserID) { identifiedCustomerInfo, created, error in
                expect(error).to(beNil())

                expect(created).to(beTrue())
                expect(identifiedCustomerInfo?.entitlements["premium"]?.isActive) == true
                completionCalled = true
            }
        }
        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
    }

    func testPurchaseMadeBeforeLogInWithExistingUserIsNotRetainedUnlessRestoreCalled() {
        var completionCalled = false
        let existingUserID = "\(#function)\(UUID().uuidString)"
        self.waitUntilCustomerInfoIsUpdated()

        // log in to create the user, then log out
        Purchases.shared.logIn(existingUserID) { logInCustomerInfo, created, logInError in
            Purchases.shared.logOut() { loggedOutCustomerInfo, logOutError in
                completionCalled = true
            }
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)

        // purchase as anonymous user, then log in
        purchaseMonthlyOffering()
        waitUntilEntitlementsGoThrough()

        completionCalled = false

        Purchases.shared.logIn(existingUserID) { customerInfo, created, logInError in
            completionCalled = true
            self.assertNoPurchases(customerInfo)
            expect(created).to(beFalse())
            expect(logInError).to(beNil())
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)

        Purchases.shared.restorePurchases()

        waitUntilEntitlementsGoThrough()
    }

    func testPurchaseAsIdentifiedThenLogOutThenRestoreGrantsEntitlements() {
        var completionCalled = false
        let existingUserID = UUID().uuidString
        self.waitUntilCustomerInfoIsUpdated()

        Purchases.shared.logIn(existingUserID) { logInCustomerInfo, created, logInError in
            self.purchaseMonthlyOffering()
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)

        waitUntilEntitlementsGoThrough()

        completionCalled = false

        Purchases.shared.logOut { customerInfo, error in
            self.assertNoPurchases(customerInfo)
            expect(error).to(beNil())
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)

        Purchases.shared.restorePurchases()

        waitUntilEntitlementsGoThrough()
    }

    func testLogInReturnsCreatedTrueWhenNewAndFalseWhenExisting() {
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "\(#function)_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        var completionCalled = false
        Purchases.shared.logIn(identifiedUserID) { identifiedCustomerInfo, created, error in
            expect(error).to(beNil())
            expect(created).to(beTrue())
            Purchases.shared.logOut { loggedOutCustomerInfo, logOutError in
                Purchases.shared.logIn(identifiedUserID) { identifiedCustomerInfo, created, error in
                    expect(error).to(beNil())
                    expect(created).to(beFalse())
                    completionCalled = true
                }
            }
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
    }

    func testLogInThenLogInAsAnotherUserWontTransferPurchases() {
        let userID1 = UUID().uuidString
        let userID2 = UUID().uuidString

        Purchases.shared.logIn(userID1) { identifiedCustomerInfo, created, error in
            self.purchaseMonthlyOffering()
        }

        waitUntilEntitlementsGoThrough()

        testSession.clearTransactions()

        Purchases.shared.logIn(userID2) { identifiedCustomerInfo, created, error in
            self.assertNoPurchases(identifiedCustomerInfo)
            expect(error).to(beNil())
        }

        expect(self.purchasesDelegate.customerInfo?.originalAppUserId)
            .toEventually(equal(userID2), timeout: Self.timeout)
        assertNoPurchases(purchasesDelegate.customerInfo)
    }

    func testLogOutRemovesEntitlements() {
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)".replacingOccurrences(of: "RCAnonymous", with: "")

        Purchases.shared.logIn(identifiedUserID) { identifiedCustomerInfo, created, error in
            expect(error).to(beNil())

            expect(created).to(beTrue())
            print("identifiedCustomerInfo: \(String(describing: identifiedCustomerInfo))")

            self.purchaseMonthlyOffering()
        }

        waitUntilEntitlementsGoThrough()

        var completionCalled = false
        Purchases.shared.logOut { loggedOutCustomerInfo, logOutError in
            expect(logOutError).to(beNil())
            self.assertNoPurchases(loggedOutCustomerInfo)
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testEligibleForIntroBeforePurchaseAndIneligibleAfter() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var productID: String?
        var completionCalled = false
        var receivedEligibility: [String: IntroEligibility]?
        
        Purchases.shared.getOfferings { offerings, error in
            productID = offerings?.current?.monthly?.storeProduct.productIdentifier
            completionCalled = true
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
        completionCalled = false
        
        let unwrappedProductID = try XCTUnwrap(productID)
        
        Purchases.shared.checkTrialOrIntroDiscountEligibility([unwrappedProductID]) { eligibility in
            completionCalled = true
            receivedEligibility = eligibility
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
        completionCalled = false
        
        var unwrappedEligibility = try XCTUnwrap(receivedEligibility)
        expect(unwrappedEligibility[unwrappedProductID]?.status) == .eligible
        
        purchaseMonthlyOffering { [self] customerInfo, error in
            expect(customerInfo?.entitlements.all.count) == 1
            let entitlements = self.purchasesDelegate.customerInfo?.entitlements
            expect(entitlements?["premium"]?.isActive) == true
            
            let anonUserID = Purchases.shared.appUserID
            let identifiedUserID = "\(#function)_\(anonUserID)_".replacingOccurrences(of: "RCAnonymous", with: "")
            
            Purchases.shared.logIn(identifiedUserID) { identifiedCustomerInfo, created, error in
                expect(error).to(beNil())
                
                expect(created).to(beTrue())
                expect(identifiedCustomerInfo?.entitlements["premium"]?.isActive) == true
                completionCalled = true
            }
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
        completionCalled = false
        
        Purchases.shared.checkTrialOrIntroDiscountEligibility([unwrappedProductID]) { eligibility in
            completionCalled = true
            receivedEligibility = eligibility
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: Self.timeout)
        
        unwrappedEligibility = try XCTUnwrap(receivedEligibility)
        expect(unwrappedEligibility[unwrappedProductID]?.status) == .ineligible
    }
    
}

private extension BackendIntegrationTests {

    func purchaseMonthlyOffering(completion: ((CustomerInfo?, Error?) -> Void)? = nil) {
        Purchases.shared.getOfferings { offerings, error in
            expect(error).to(beNil())

            let offering = offerings?.current
            expect(offering).toNot(beNil())
            
            let monthlyPackage = offering?.monthly
            expect(monthlyPackage).toNot(beNil())

            Purchases.shared.purchase(package: monthlyPackage!) { transaction,
                                                                  customerInfo,
                                                                  purchaseError,
                                                                  userCancelled in
                expect(purchaseError).to(beNil())
                expect(customerInfo).toNot(beNil())
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                Purchases.shared.syncPurchases(completion: completion)
            }
        }
    }

    func configurePurchases() {
        purchasesDelegate = TestPurchaseDelegate()
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        Purchases.logLevel = .debug
        Purchases.shared.delegate = purchasesDelegate
    }

    func waitUntilEntitlementsGoThrough() {
        expect(self.purchasesDelegate.customerInfo?.entitlements.all.count)
            .toEventually(equal(1), timeout: Self.timeout)
    }

    func assertNoPurchases(_ customerInfo: CustomerInfo?) {
        expect(customerInfo?.entitlements.all.count) == 0
    }

    func waitUntilCustomerInfoIsUpdated() {
        expect(self.purchasesDelegate.customerInfoUpdateCount).toEventually(equal(1), timeout: Self.timeout)
    }
    
}
