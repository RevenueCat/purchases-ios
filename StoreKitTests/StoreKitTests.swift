//
//  StoreKitTests.swift
//  StoreKitTests
//
//  Created by Andrés Boedo on 5/3/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import XCTest
import Purchases
import Nimble
import StoreKitTest

class TestPurchaseDelegate: NSObject, PurchasesDelegate {
    var purchaserInfo: Purchases.PurchaserInfo?
    var purchaserInfoUpdateCount = 0
    
    func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: Purchases.PurchaserInfo) {
        self.purchaserInfo = purchaserInfo
        purchaserInfoUpdateCount += 1
    }
    
    func purchases(_ purchases: Purchases, shouldPurchasePromoProduct product: SKProduct, defermentBlock makeDeferredPurchase: @escaping RCDeferredPromotionalPurchaseBlock) {
        
    }
    
}

class StoreKitTests: XCTestCase {
    
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
        var receivedOfferings: Purchases.Offerings? = nil
        Purchases.shared.offerings { offerings, error in
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
        
        expect(self.purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
        let entitlements = purchasesDelegate.purchaserInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
    }
    
    
    func testPurchaseMadeBeforeLogInIsRetainedAfter() {
        configurePurchases()
        
        purchaseMonthlyOffering()
        
        expect(self.purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
        let entitlements = purchasesDelegate.purchaserInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
        
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)"
        
        var completionCalled = false
        Purchases.shared.logIn(identifiedUserID) { identifiedPurchaserInfo, created, error in
            expect(error).to(beNil())
            
            expect(created).to(beTrue())
            expect(identifiedPurchaserInfo?.entitlements["premium"]?.isActive) == true
            completionCalled = true
            print("identifiedPurchaserInfo: \(String(describing: identifiedPurchaserInfo))")
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
    }
    
    func testPurchaseMadeBeforeLogInIsNotRetainedAfterIfLogInToExistingUser() {
        configurePurchases()
        var completionCalled = false
        let existingUserID = UUID().uuidString
        expect(self.purchasesDelegate.purchaserInfoUpdateCount).toEventually(equal(1), timeout: .seconds(10))
        
        Purchases.shared.logIn(existingUserID) { logInPurchaserInfo, created, logInError in
            Purchases.shared.logOut() { loggedOutPurchaserInfo, logOutError in
                completionCalled = true
            }
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))

        purchaseMonthlyOffering()
        expect(self.purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
        
        testSession.clearTransactions()
        
        completionCalled = false
        
        Purchases.shared.logIn(existingUserID) { purchaserInfo, created, logInError in
            completionCalled = true
            expect(purchaserInfo?.entitlements.all.count) == 0
            expect(created).to(beFalse())
            expect(logInError).to(beNil())
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
        
        Purchases.shared.restoreTransactions()
        
        expect(self.purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
    }
    
    func testLogInReturnsCreatedTrueWhenNewAndFalseWhenExisting() {
        configurePurchases()
        
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)".replacingOccurrences(of: "RCAnon", with: "")
        
        var completionCalled = false
        Purchases.shared.logIn(identifiedUserID) { identifiedPurchaserInfo, created, error in
            expect(error).to(beNil())
            expect(created).to(beTrue())
            Purchases.shared.logOut { loggedOutPurchaserInfo, logOutError in
                Purchases.shared.logIn(identifiedUserID) { identifiedPurchaserInfo, created, error in
                    expect(error).to(beNil())
                    expect(created).to(beFalse())
                    completionCalled = true
                }
            }
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
    }
    
    func testLogOutRemovesEntitlements() {
        configurePurchases()
        
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)".replacingOccurrences(of: "RCAnon", with: "")
        
        Purchases.shared.logIn(identifiedUserID) { identifiedPurchaserInfo, created, error in
            expect(error).to(beNil())
            
            expect(created).to(beTrue())
            print("identifiedPurchaserInfo: \(String(describing: identifiedPurchaserInfo))")
            
            self.purchaseMonthlyOffering()
         }
        
        expect(self.purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
        
        var completionCalled = false
        Purchases.shared.logOut { loggedOutPurchaserInfo, logOutError in
            expect(logOutError).to(beNil())
            expect(loggedOutPurchaserInfo?.entitlements.all.count) == 0
            completionCalled = true
        }
        
        expect(completionCalled).toEventually(beTrue(), timeout: .seconds(10))
    }
    
}

private extension StoreKitTests {
        
    func purchaseMonthlyOffering() {
        Purchases.shared.offerings { offerings, error in
            expect(error).to(beNil())
            
            let offering = offerings?.current
            expect(offering).toNot(beNil())
            
            let monthlyPackage = offering?.monthly
            expect(monthlyPackage).toNot(beNil())
            
            Purchases.shared.purchaseProduct(monthlyPackage!.product) { transaction, purchaserInfo, purchaseError, userCancelled in
                expect(purchaseError).to(beNil())
                expect(purchaserInfo).toNot(beNil())
            }
            
            Purchases.shared.syncPurchases()
        }
    }
    
    func configurePurchases() {
        purchasesDelegate = TestPurchaseDelegate()
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        Purchases.debugLogsEnabled = true
        Purchases.shared.delegate = purchasesDelegate
    }
}
