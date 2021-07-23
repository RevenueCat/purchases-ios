//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerTests.swift
//
//  Created by Andrés Boedo on 7/23/21.

@testable import PurchasesCoreSwift
import Nimble
import StoreKitTest
import XCTest


class ProductsManagerTests: XCTestCase {

    var testSession: SKTestSession!
    var userDefaults: UserDefaults!
    var productsManager: ProductsManager!

    override func setUpWithError() throws {
        testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        testSession.disableDialogs = true
        testSession.clearTransactions()
        productsManager = ProductsManager()
    }

    @available(iOS 15.0, tvOS 15.0, macOS 13.0, watchOS 7.0, *)
    func testFetchProductsFromOptimalStore() {
        let identifiers = Set([
            "com.revenuecat.monthly_4.99.1_week_intro"
        ])
        var completionCalled = false
        var receivedProducts: Set<ProductWrapper>?
        let products = productsManager.productsFromOptimalStore(withIdentifiers: identifiers, completion: { products in
            completionCalled = true
            receivedProducts = products
        })
        expect(completionCalled).toEventually(beTrue())
        expect(receivedProducts?.count) == 1
        let firstProduct = receivedProducts!.first!
        expect(firstProduct as? SK1ProductWrapper).toNot(beNil())
    }
}
