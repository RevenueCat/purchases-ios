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
    
    override func tearDownWithError() throws {
        testSession.clearTransactions()
    }
    
    func testCanGetOfferings() throws {
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        Purchases.debugLogsEnabled = true
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
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        Purchases.debugLogsEnabled = true
        let purchasesDelegate = TestPurchaseDelegate()
        Purchases.shared.delegate = purchasesDelegate
        
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
        
        expect(purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
        let entitlements = purchasesDelegate.purchaserInfo?.entitlements
        expect(entitlements?["premium"]?.isActive) == true
    }
    
    func testPurchaseMadeBeforeLogInIsRetainedAfter() {
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        Purchases.debugLogsEnabled = true
        let purchasesDelegate = TestPurchaseDelegate()
        Purchases.shared.delegate = purchasesDelegate
        
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
        
        expect(purchasesDelegate.purchaserInfo?.entitlements.all.count).toEventually(equal(1), timeout: .seconds(10))
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
    
    func testLogInReturnsCreatedTrueWhenNewAndFalseWhenExisting() {
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: userDefaults)
        Purchases.debugLogsEnabled = true
        
        let anonUserID = Purchases.shared.appUserID
        let identifiedUserID = "identified_\(anonUserID)"
        
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
    
}
