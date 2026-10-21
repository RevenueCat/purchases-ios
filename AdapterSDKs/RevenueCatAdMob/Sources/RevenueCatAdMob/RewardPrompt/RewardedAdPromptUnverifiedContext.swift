//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptUnverifiedContext.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)

/// Actions provided to a ``RewardedAdPromptWithoutVerification`` content builder.
/// The app defines the offer and is responsible for granting its own reward.
@available(iOS 15.0, *)
@MainActor
public struct RewardedAdPromptUnverifiedContext {

    private let acceptAction: @MainActor () -> Void

    init(acceptAction: @escaping @MainActor () -> Void) {
        self.acceptAction = acceptAction
    }

    /// Accepts the prompt, tracks the acceptance, and presents the loaded rewarded ad.
    ///
    /// Only the first call for a rendered prompt has an effect.
    /// If no attached presentation controller is available, `onResult` reports `.notPresented`
    /// asynchronously after this method returns.
    public func accept() {
        self.acceptAction()
    }

}

#endif
