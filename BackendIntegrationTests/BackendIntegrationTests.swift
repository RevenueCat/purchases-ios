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
    var maybeCustomerInfo: CustomerInfo?
    var customerInfoUpdateCount = 0

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        self.maybeCustomerInfo = customerInfo
        customerInfoUpdateCount += 1
    }

    func purchases(_ purchases: Purchases,
                   shouldPurchasePromoProduct product: SK1Product,
                   defermentBlock makeDeferredPurchase: @escaping DeferredPromotionalPurchaseBlock) {
    }
}

class BackendIntegrationTests: XCTestCase {

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!
    var purchasesDelegate: TestPurchaseDelegate!

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        testSession.disableDialogs = true
        testSession.clearTransactions()

        userDefaults = UserDefaults(suiteName: Constants.userDefaultsSuiteName)
        userDefaults?.removePersistentDomain(forName: Constants.userDefaultsSuiteName)
        if !Constants.proxyURL.isEmpty {
            Purchases.proxyURL = URL(string: Constants.proxyURL)
        }
    }

    func testCanGetOfferings() throws {
        configurePurchases()
        var completionCalled = false
        var receivedError: Error? = nil
        var receivedOfferings: Offerings? = nil
        Purchases.shared.getOfferings { offerings, error in
            completionCalled = true
            receivedError = error
            receivedOfferings = offerings
        }
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))

        expect(receivedError).to(beNil())
        expect(receivedOfferings).toNot(beNil())
        expect(receivedOfferings!.all).toNot(beEmpty())
    }

    func testCanMakePurchase() throws {
        configurePurchases()
        purchaseMonthlyOffering()

        waitUntilEntitlementsGoThrough()
        let entitlements = purchasesDelegate.maybeCustomerInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
    }

    func testPurchaseMadeBeforeLogInIsRetainedAfter() {
        configurePurchases()

        var completionCalled = false
        purchaseMonthlyOffering { [self] customerInfo, error in
            expect(customerInfo?.entitlements.all.count) == 1
            let entitlements = self.purchasesDelegate.maybeCustomerInfo?.entitlements
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
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
    }

    func testPurchaseMadeBeforeLogInWithExistingUserIsNotRetainedUnlessRestoreCalled() {
        configurePurchases()
        var completionCalled = false
        let existingUserID = "\(#function)\(UUID().uuidString)"
        expect(self.purchasesDelegate.customerInfoUpdateCount).toEventually(equal(1), timeout: .seconds(10))

        // log in to create the user, then log out
        Purchases.shared.logIn(existingUserID) { logInCustomerInfo, created, logInError in
            Purchases.shared.logOut() { loggedOutCustomerInfo, logOutError in
                completionCalled = true
            }
        }

        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))

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

        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))

        Purchases.shared.restoreTransactions()

        waitUntilEntitlementsGoThrough()
    }

    func testPurchaseAsIdentifiedThenLogOutThenRestoreGrantsEntitlements() {
        configurePurchases()
        var completionCalled = false
        let existingUserID = UUID().uuidString
        expect(self.purchasesDelegate.customerInfoUpdateCount).toEventually(equal(1), timeout: .seconds(10))

        Purchases.shared.logIn(existingUserID) { logInCustomerInfo, created, logInError in
            self.purchaseMonthlyOffering()
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))

        waitUntilEntitlementsGoThrough()

        completionCalled = false

        Purchases.shared.logOut { customerInfo, error in
            self.assertNoPurchases(customerInfo)
            expect(error).to(beNil())
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))

        Purchases.shared.restoreTransactions()

        waitUntilEntitlementsGoThrough()
    }

    func testLogInReturnsCreatedTrueWhenNewAndFalseWhenExisting() {
        configurePurchases()

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

        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
    }

    func testLogInThenLogInAsAnotherUserWontTransferPurchases() {
        configurePurchases()

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

        expect(self.purchasesDelegate.maybeCustomerInfo?.originalAppUserId)
            .toEventually(equal(userID2), timeout: .seconds(10))
        assertNoPurchases(purchasesDelegate.maybeCustomerInfo)
    }

    func testLogOutRemovesEntitlements() {
        configurePurchases()

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

        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
    }

    // - Note: Xcode throws a warning about @available and #available being redundant, but they're actually necessary:
    // Although the method isn't supposed to be called because of our @available marks,
    // everything in this class will still be called by XCTest, and it will cause errors.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testEligibleForIntroBeforePurchaseAndIneligibleAfter() throws {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        configurePurchases()
        
        var maybeProductID: String?
        var completionCalled = false
        var maybeReceivedEligibility: [String: IntroEligibility]?
        
        Purchases.shared.getOfferings { offerings, error in
            maybeProductID = offerings?.current?.monthly?.storeProduct.productIdentifier
            completionCalled = true
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
        completionCalled = false
        
        let productID = try XCTUnwrap(maybeProductID)
        
        Purchases.shared.checkTrialOrIntroductoryPriceEligibility([productID]) { receivedEligibility in
            completionCalled = true
            maybeReceivedEligibility = receivedEligibility
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
        completionCalled = false
        
        var receivedEligibility = try XCTUnwrap(maybeReceivedEligibility)
        expect(receivedEligibility[productID]?.status) == .eligible
        
        purchaseMonthlyOffering { [self] customerInfo, error in
            expect(customerInfo?.entitlements.all.count) == 1
            let entitlements = self.purchasesDelegate.maybeCustomerInfo?.entitlements
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
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
        completionCalled = false
        
        Purchases.shared.checkTrialOrIntroductoryPriceEligibility([productID]) { receivedEligibility in
            completionCalled = true
            maybeReceivedEligibility = receivedEligibility
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
        
        receivedEligibility = try XCTUnwrap(maybeReceivedEligibility)
        expect(receivedEligibility[productID]?.status) == .ineligible
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
        expect(self.purchasesDelegate.maybeCustomerInfo?.entitlements.all.count)
            .toEventually(equal(1), timeout: .seconds(10))
    }

    func assertNoPurchases(_ customerInfo: CustomerInfo?) {
        expect(customerInfo?.entitlements.all.count) == 0
    }
}
