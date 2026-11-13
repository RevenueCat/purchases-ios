//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MultiSeatSheetPresenterType.swift
//
//  Created by Will Taylor on 11/13/26.

import Foundation
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

/// Abstraction over StoreKit's multi-seat sheet presentation APIs, so they can be easily mocked in tests.
internal protocol MultiSeatSheetPresenterType: Sendable {

    #if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit) && ENABLE_MULTISEAT_PURCHASES
    @available(iOS 27.3, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(visionOS, unavailable)
    @MainActor
    func presentMultiSeatInvitationSheet(
        from controller: UIViewController,
        subscriptionGroupID: String
    ) async throws
    #endif

}

/// Default ``MultiSeatSheetPresenterType`` that forwards to `StoreKit.AppStore`.
final internal struct StoreKitMultiSeatSheetPresenter: MultiSeatSheetPresenterType {

    #if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit) && ENABLE_MULTISEAT_PURCHASES
    @available(iOS 27.3, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(visionOS, unavailable)
    @MainActor
    func presentMultiSeatInvitationSheet(
        from controller: UIViewController,
        subscriptionGroupID: String
    ) async throws {
        try await StoreKit.AppStore.presentMultiSeatInvitationSheet(
            from: controller,
            subscriptionGroupID: subscriptionGroupID
        )
    }
    #endif

}
