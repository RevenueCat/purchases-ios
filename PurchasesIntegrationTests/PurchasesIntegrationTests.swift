//
//  PurchasesIntegrationTests.swift
//  PurchasesIntegrationTests
//
//  Created by Andrés Boedo on 7/13/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest
import StoreKitTest
import StoreKit
@testable import Purchases


class PurchasesIntegrationTests: XCTestCase {
    
    var testSession: SKTestSession!
    var apiKey: String!
    var integrationTestsURL: URL?
    var userDefaults: UserDefaults!
    
    override func setUp() {
        testSession = try! SKTestSession(configurationFileNamed: "Configuration")
        
        testSession.disableDialogs = true
        testSession.clearTransactions()
        
        apiKey = <api_key_for_integration_tests_here>
        userDefaults = .standard
        
        Purchases.proxyURL = integrationTestsURL
    }
    
    func testGetOfferings() {
        Purchases.configure(withAPIKey: apiKey, appUserID: "andyIntegrationTests", observerMode: false, userDefaults: userDefaults)
        let expectation = XCTestExpectation(description: "finish all async calls")
        
        Purchases.shared.offerings { offerings, error in
            if let error = error {
                print("error found while fetching offerings: \(error.localizedDescription)")
                expectation.fulfill()
                return
            }
            
            guard let offerings = offerings,
                  let currentOffering = offerings.current else {
                print("couldn't unpack package")
                expectation.fulfill()
                return
            }
            let packages = currentOffering.availablePackages
            guard let currentPackage = packages.first else {
                print("packages is empty")
                expectation.fulfill()
                return
            }
            
            Purchases.shared.purchasePackage(currentPackage) { (transaction, purchaserInfo, error, cancelled) in
                if let error = error {
                    print("error found while purchasing package: \(error.localizedDescription)")
                    expectation.fulfill()
                    return
                }
                print("transaction: \(String(describing: transaction))")
                print("purchaserInfo: \(String(describing: purchaserInfo))")
                print("userCancelled: \(cancelled)")
                let productId = currentPackage.product.productIdentifier
                Purchases.shared.checkTrialOrIntroductoryPriceEligibility([productId, "unknown product id"]) { introEligibility in
                    print("finished")
                    print("intro eligibility: \(introEligibility)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    
    func testParseReceipt2() {
        testSession = try! SKTestSession(configurationFileNamed: "Configuration")
        
        testSession.disableDialogs = true
        testSession.clearTransactions()
        let productId = "com.revenuecat.annual_39.99.2_week_intro"
        try! testSession.buyProduct(productIdentifier: productId)
        let userDefaults: UserDefaults = .standard
        Purchases.configure(withAPIKey: "VtDdmbdWBySmqJeeQUTyrNxETUVkhuaJ", appUserID: "andyIntegrationTests", observerMode: false, userDefaults: userDefaults)
        let expectation = XCTestExpectation(description: "finish all async calls")
        
        Purchases.shared.checkTrialOrIntroductoryPriceEligibility([productId, "lalala"]) { introEligibility in
            print("finished")
            print("intro eligibility: \(introEligibility)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
        
        
    }
}

