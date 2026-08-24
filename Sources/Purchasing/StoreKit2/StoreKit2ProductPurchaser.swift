//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2ProductPurchaser.swift
//
//  Created by Will Taylor on 2/25/25.

import Foundation
import StoreKit

internal protocol StoreKit2ProductPurchaserType {

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(
        product: PurchasableSK2Product,
        options: Set<StoreKit.Product.PurchaseOption>,
        storeKit2ConfirmInOptions: StoreKit2ConfirmInOptions?
    ) async throws -> StoreKit.Product.PurchaseResult
}

internal class StoreKit2ProductPurchaser: StoreKit2ProductPurchaserType {

    private let systemInfo: SystemInfo

    init(
        systemInfo: SystemInfo
    ) {
        self.systemInfo = systemInfo
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func purchase(
        product: PurchasableSK2Product,
        options: Set<StoreKit.Product.PurchaseOption>,
        storeKit2ConfirmInOptions: StoreKit2ConfirmInOptions?
    ) async throws -> StoreKit.Product.PurchaseResult {
#if VISION_OS
        let scene: UIScene
        if let confirmInScene = storeKit2ConfirmInOptions?.confirmInScene {
            scene = confirmInScene
        } else {
            scene = try await self.systemInfo.currentWindowScene
        }

        return try await product.purchase(confirmIn: scene, options: options)

        // purchase(confirmIn:options:) with UIScenes was introduced in iOS 17.0,
        // which shipped with Xcode 15.0 and the Swift 5.9.0 compiler.
        //
        // watchOS is excluded here since purchase(confirmIn:options:) isn't supported on watchOS.
#elseif canImport(UIKit) && compiler(>=5.9.0) && !os(watchOS)

        if let confirmInScene = storeKit2ConfirmInOptions?.confirmInScene,
           #available(iOS 17.0, iOSApplicationExtension 17.0, macCatalyst 17.0, tvOS 17.0, *) {
            return try await product.purchase(confirmIn: confirmInScene, options: options)
        } else {
            return try await product.purchase(options: options)
        }

        // purchase(confirmIn:options:) with NSWindows was introduced in macOS 15.2,
        // which shipped with Xcode 16.2 and the Swift 6.0.2 compiler.
#elseif canImport(AppKit) && compiler(>=6.0.2) && !targetEnvironment(macCatalyst)

        if let confirmInWindow = storeKit2ConfirmInOptions?.confirmInWindow,
           #available(macOS 15.2, *) {
            return try await product.purchase(confirmIn: confirmInWindow, options: options)
        } else {
            return try await product.purchase(options: options)
        }

#else
        // If we don't have a confirmIn option, or if the platform doesn't support it,
        // we'll call purchase(options:) directly.
        return try await product.purchase(options: options)
#endif
    }
}
