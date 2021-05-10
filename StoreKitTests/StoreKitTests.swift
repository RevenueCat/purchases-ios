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
}
