//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferCodeRedemptionSheetPresenter.swift
//
//  Created by Will Taylor on 10/17/24.

import Foundation
import StoreKit

@objc protocol OfferCodeRedemptionSheetPresenterType {

    @available(iOS 14.0, *)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst 16.0, *)
    func presentCodeRedemptionSheet(windowScene: UIWindowScene)
}

final internal class OfferCodeRedemptionSheetPresenter: OfferCodeRedemptionSheetPresenterType {

    private var presentSheetTask: Task<Void, Never>?

    private let paymentQueue: SKPaymentQueue

    init(
        paymentQueue: SKPaymentQueue = .default()
    ) {
        self.paymentQueue = paymentQueue
    }

    @available(iOS 14.0, *)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst 16.0, *)
    func presentCodeRedemptionSheet(
        windowScene: UIWindowScene
    ) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if ProcessInfo().operatingSystemVersion.majorVersion < 16 {
            // .presentOfferCodeRedeemSheet(in: windowScene) isn't available in iOS <16, so fall back
            // to the SK1 implementation
            self.sk1PresentCodeRedemptionSheet()
            return
        }
        #endif

        self.presentSheetTask = Task.detached { @MainActor in
            if #available(iOSApplicationExtension 16.0, *), #available(iOS 16.0, *) {
                try? await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
            } else {
                // TODO: Log failure
            }
        }
    }

    @available(iOS 14.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    private func sk1PresentCodeRedemptionSheet() {
        self.paymentQueue.presentCodeRedemptionSheet()
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol UIWindowSceneFinderType {
    func attemptToGetActiveWindowScene() -> UIWindowScene?
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
struct UIWindowSceneFinder: UIWindowSceneFinderType {
    func attemptToGetActiveWindowScene() -> UIWindowScene? {
            UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}
