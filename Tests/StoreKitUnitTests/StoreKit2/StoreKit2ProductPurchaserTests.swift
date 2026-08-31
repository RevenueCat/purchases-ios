//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ProductPurchaserTests.swift
//
//  Created by Will Taylor on 2/25/25.

import Foundation
import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class StoreKit2ProductPurchaserTests: StoreKitConfigTestCase {

    private var storeKit2ProductPurchaser: StoreKit2ProductPurchaserType!

    override func setUp() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
        let systemInfo = MockSystemInfo(finishTransactions: true)
        self.storeKit2ProductPurchaser = StoreKit2ProductPurchaser(systemInfo: systemInfo)
    }

    // MARK: - iOS/iPadOS/tvOS/macCatalyst Purchase Tests
    func testPurchaseWithUISceneCallsPurchaseWithConfirmInUIScene() async throws {
        #if canImport(UIKit) && !os(watchOS)
        let mockProduct: MockPurchasableSK2Product = MockPurchasableSK2Product()

        guard let scene = await UIScene.mock() else {
            fail("Failed to create UIScene mock")
            return
        }
        let sk2ConfirmInOptions = StoreKit2ConfirmInOptions(confirmInScene: scene)
        let options: Set<Product.PurchaseOption> = []

        _ = try await storeKit2ProductPurchaser.purchase(
            product: mockProduct,
            options: options,
            storeKit2ConfirmInOptions: sk2ConfirmInOptions
        )

        #if compiler(>=5.9.0)
        // product.purchase(confirmIn:options:) was introduced in iOS 17.0/Swift 5.9.0
        if #available(iOS 17.0, iOSApplicationExtension 17.0, macCatalyst 17.0, tvOS 17.0, *) {
            confirmPurchaseConfirmInSceneWithOptionsExpectations(
                on: mockProduct,
                scene: scene,
                options: options
            )
        } else {
            // iOS <= 17.0
            confirmPurchaseWithOptionsExpectations(on: mockProduct, options: options)
        }

        #else
        // iOS apps built with Swift <= 5.9.0
        confirmPurchaseWithOptionsExpectations(on: mockProduct, options: options)
        #endif

        // Don't do anything for platforms that don't support UIScene
        #endif
    }

    // MARK: - macOS Purchase Tests
    func testMacOSPurchaseWithNSWindowCallsPurchaseWithConfirmInNSWindow() async throws {
        #if os(macOS) && !targetEnvironment(macCatalyst)
        let mockProduct: MockPurchasableSK2Product = MockPurchasableSK2Product()

        guard let window = await NSWindow.mock() else {
            fail("Failed to create UIScene mock")
            return
        }
        let sk2ConfirmInOptions = StoreKit2ConfirmInOptions(confirmInWindow: window)
        let options: Set<Product.PurchaseOption> = []

        _ = try await storeKit2ProductPurchaser.purchase(
            product: mockProduct,
            options: options,
            storeKit2ConfirmInOptions: sk2ConfirmInOptions
        )

        // product.purchase(confirmIn:options:) was introduced in macOS 15.2/Swift 6.0.2
        #if compiler(>=6.0.2)
        if #available(macOS 15.2, *) {
            confirmPurchaseConfirmInWindowWithOptionsExpectations(
                on: mockProduct,
                window: window,
                options: options
            )
        } else {
            // macOS apps on macOS <= 15.2
            confirmPurchaseWithOptionsExpectations(on: mockProduct, options: options)
        }
        #else
        // macOS apps built with Swift <= 6.0.2
        confirmPurchaseWithOptionsExpectations(on: mockProduct, options: options)
        #endif

        // Nothing needs to be done for macOS tests on other platforms
        #endif
    }

    // MARK: - Non-VisionOS Universal Tests
    func testPurchaseWithoutConfirmInCallsPurchaseWithOptions() async throws {
        #if !os(visionOS)
        let mockProduct: MockPurchasableSK2Product = MockPurchasableSK2Product()
        let options: Set<Product.PurchaseOption> = []

        _ = try await storeKit2ProductPurchaser.purchase(
            product: mockProduct,
            options: options,
            storeKit2ConfirmInOptions: nil
        )

        confirmPurchaseWithOptionsExpectations(on: mockProduct, options: options)
        #endif
    }

    // MARK: - Expectation Confirmation Helpers
    private func confirmPurchaseWithOptionsExpectations(
        on product: MockPurchasableSK2Product,
        options: Set<StoreKit.Product.PurchaseOption>
    ) {
        expect(product.calledPurchaseWithOptions).to(beTrue())
        expect(product.calledPurchaseWithOptionsOptions).to(equal(options))
    }

    #if canImport(UIKit) && !os(watchOS)
    private func confirmPurchaseConfirmInSceneWithOptionsExpectations(
        on product: MockPurchasableSK2Product,
        scene: UIScene,
        options: Set<StoreKit.Product.PurchaseOption>
    ) {
        expect(product.calledPurchaseConfirmInSceneWithOptions).to(beTrue())
        expect(product.calledPurchaseConfirmInSceneWithOptionsScene).to(equal(scene))
        expect(product.calledPurchaseConfirmInSceneWithOptionsOptions).to(equal(options))
    }
    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private func confirmPurchaseConfirmInWindowWithOptionsExpectations(
        on product: MockPurchasableSK2Product,
        window: NSWindow,
        options: Set<StoreKit.Product.PurchaseOption>
    ) {
        expect(product.calledPurchaseConfirmInWindowWithOptions).to(beTrue())
        expect(product.calledPurchaseConfirmInWindowWithOptionsWindow).to(equal(window))
        expect(product.calledPurchaseConfirmInWindowWithOptionsOptions).to(equal(options))
    }
    #endif
}
