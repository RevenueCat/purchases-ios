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

import Nimble
import StoreKitTest
@testable import RevenueCat
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

    func testFetchProductsFromOptimalStore() throws {
        let identifier = "com.revenuecat.monthly_4.99.1_week_intro"
        var completionCalled = false
        var maybeReceivedProducts: Set<ProductDetails>?

        productsManager.productsFromOptimalStore(withIdentifiers: Set([identifier]), completion: { products in
            completionCalled = true
            maybeReceivedProducts = products
        })

        expect(completionCalled).toEventually(beTrue())
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts.count) == 1

        let firstProduct = try XCTUnwrap(receivedProducts.first)

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            expect(firstProduct as? SK2ProductDetails).toNot(beNil())
        } else {
            expect(firstProduct as? SK1ProductDetails).toNot(beNil())
        }
        expect(firstProduct.productIdentifier) == identifier
    }
}
