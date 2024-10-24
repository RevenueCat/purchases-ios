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

@objc protocol OfferCodeRedemptionSheetPresenterType: Sendable {

    #if (os(iOS) || VISION_OS) && !targetEnvironment(macCatalyst)
    @available(iOS 14.0, *)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func presentCodeRedemptionSheet(
        windowScene: UIWindowScene,
        storeKitVersion: StoreKitVersion
    ) async throws
    #endif
}

final internal class OfferCodeRedemptionSheetPresenter: OfferCodeRedemptionSheetPresenterType, Sendable {

    private let paymentQueue: SKPaymentQueue
    private let isiOSAppOnMac: Bool
    private let osMajorVersion: Int

    init(
        paymentQueue: SKPaymentQueue = .default(),
        isiOSAppOnMac: Bool = {
            if #available(
                iOS 14.0,
                iOSApplicationExtension 14.0,
                macOS 11.0,
                watchOS 7.0,
                tvOS 14.0,
                *
            ) {
                return ProcessInfo().isiOSAppOnMac
            } else {
                return false
            }
        }(),
        osMajorVersion: Int = {
            return ProcessInfo().operatingSystemVersion.majorVersion
        }()
    ) {
        self.paymentQueue = paymentQueue
        self.isiOSAppOnMac = isiOSAppOnMac
        self.osMajorVersion = osMajorVersion
    }

    #if (os(iOS) || VISION_OS) && !targetEnvironment(macCatalyst)
    @available(iOS 14.0, *)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func presentCodeRedemptionSheet(
        windowScene: UIWindowScene,
        storeKitVersion: StoreKitVersion
    ) async throws {

        // Presenting the Offer Code Redemption sheet throws/crashes when running an iOS app
        // as "Designed for iPad" on macOS, so we don't want to call it when the app is running on macOS
        // as a "Designed for iPad" app.
        if isiOSAppOnMac {
            Logger.warn(Strings.storeKit.not_displaying_offer_code_redemption_sheet_because_ios_app_on_macos)
            return
        }

        if storeKitVersion.isStoreKit2EnabledAndAvailable {
            if osMajorVersion < 16 {
                // .presentOfferCodeRedeemSheet(in: windowScene) isn't available in iOS <16, so fall back
                // to the SK1 implementation
                self.sk1PresentCodeRedemptionSheet()
                return
            }

            if #available(iOS 16.0, iOSApplicationExtension 16.0, *) {
                try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
            } else {
                // This case should be covered by the above OS check, but we'll include here
                // since it's a possible code case
                #if !targetEnvironment(macCatalyst)
                self.sk1PresentCodeRedemptionSheet()
                #else
                Logger.warn(Strings.storeKit.error_displaying_offer_code_redemption_sheet_unavailable_in_app_extension)
                #endif
            }
        } else {
            self.sk1PresentCodeRedemptionSheet()
        }

    }
    #endif

    #if os(iOS) || VISION_OS
    @available(iOS 14.0, iOSApplicationExtension 14.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    func sk1PresentCodeRedemptionSheet() {
        self.paymentQueue.presentCodeRedemptionSheet()
    }
    #endif
}
