//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPurchasableSK2Product.swift
//
//  Created by Will Taylor on 2/25/25.

import Foundation
@testable import RevenueCat
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
final class MockPurchasableSK2Product: PurchasableSK2Product, @unchecked Sendable {

    init() {}

    var calledPurchaseWithOptions = false
    var calledPurchaseWithOptionsOptions: Set<Product.PurchaseOption>?
    func purchase(options: Set<Product.PurchaseOption>) async throws -> Product.PurchaseResult {
        self.calledPurchaseWithOptions = true
        self.calledPurchaseWithOptionsOptions = options
        return .pending
    }

    #if canImport(UIKit) && !os(watchOS)
    var calledPurchaseConfirmInSceneWithOptions = false
    var calledPurchaseConfirmInSceneWithOptionsScene: UIScene?
    var calledPurchaseConfirmInSceneWithOptionsOptions: Set<Product.PurchaseOption>?
    func purchase(
        confirmIn scene: some UIScene,
        options: Set<Product.PurchaseOption>
    ) async throws -> Product.PurchaseResult {
        self.calledPurchaseConfirmInSceneWithOptions = true
        self.calledPurchaseConfirmInSceneWithOptionsScene = scene
        self.calledPurchaseConfirmInSceneWithOptionsOptions = options
        return .pending
    }
    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    var calledPurchaseConfirmInWindowWithOptions = false
    var calledPurchaseConfirmInWindowWithOptionsWindow: NSWindow?
    var calledPurchaseConfirmInWindowWithOptionsOptions: Set<Product.PurchaseOption>?
    func purchase(
        confirmIn window: NSWindow,
        options: Set<Product.PurchaseOption>
    ) async throws -> Product.PurchaseResult {
        self.calledPurchaseConfirmInWindowWithOptions = true
        self.calledPurchaseConfirmInWindowWithOptionsWindow = window
        self.calledPurchaseConfirmInWindowWithOptionsOptions = options
        return .pending
    }
    #endif
}
