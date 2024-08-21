//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WrongPlatformView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

#if CUSTOMER_CENTER_ENABLED

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct WrongPlatformView: View {

    @State
    private var store: Store?

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme
    @Environment(\.supportInformation)
    private var supportInformation: CustomerCenterConfigData.Support?
    @Environment(\.openURL)
    private var openURL

    private var supportURL: URL? {
        guard let supportInformation = self.supportInformation else { return nil }
        let subject = self.localization.commonLocalizedString(for: .defaultSubject)
        let body = self.localization.commonLocalizedString(for: .defaultBody)
        return URLUtilities.createMailURLIfPossible(email: supportInformation.email,
                                                    subject: subject,
                                                    body: body)
    }

    init() {
    }

    fileprivate init(store: Store) {
        self._store = State(initialValue: store)
    }

    var body: some View {
        List {
            Section {
                let platformInstructions = self.humanReadableInstructions(for: store)

                CompatibilityContentUnavailableView(
                    platformInstructions.0,
                    systemImage: "exclamationmark.triangle.fill",
                    description: Text(platformInstructions.1)
                )
            }
            if let url = supportURL {
                Section {
                    AsyncButton {
                        openURL(url)
                    } label: {
                        Text(localization.commonLocalizedString(for: .contactSupport))
                    }
                }
            }

        }
        .toolbar {
            ToolbarItem(placement: .compatibleTopBarTrailing) {
                DismissCircleButton {
                    dismiss()
                }
            }
        }
        .task {
            if store == nil {
                if let customerInfo = try? await Purchases.shared.customerInfo(),
                   let firstEntitlement = customerInfo.entitlements.active.first {
                    self.store = firstEntitlement.value.store
                }
            }
        }
    }

    private func humanReadablePlatformName(store: Store) -> String {
        switch store {
        case .appStore, .macAppStore:
            return "Apple App Store"
        case .playStore:
            return "Google Play Store"
        case .stripe,
                .rcBilling,
                .external:
            return "Web"
        case .promotional:
            return "Free"
        case .amazon:
            return "Amazon Appstore"
        case .unknownStore:
            return "Unknown"
        }
    }

    private func humanReadableInstructions(for store: Store?) -> (String, String) {
        let defaultContactSupport = "Please contact support to manage your subscription."

        if let store {
            let platformName = humanReadablePlatformName(store: store)

            switch store {
            case .appStore, .macAppStore:
                return (
                    "You have an \(platformName) subscription.",
                    "You can manage your subscription via the App Store app on an Apple device."
                )
            case .playStore:
                return (
                    "You have a \(platformName) subscription.",
                    "You can manage your subscription via the Google Play app on an Android device."
                )
            case .stripe, .rcBilling, .external:
                return ("Active \(platformName) Subscription", defaultContactSupport)
            case .promotional:
                return ("Active \(platformName) Subscription", defaultContactSupport)
            case .amazon:
                return (
                    "You have an \(platformName) subscription.",
                    "You can manage your subscription via the Amazon Appstore app."
                )
            case .unknownStore:
                return ("Unknown Subscription", defaultContactSupport)
            }
        } else {
            return ("Unknown Subscription", defaultContactSupport)
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct WrongPlatformView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            WrongPlatformView(store: .appStore)
                .previewDisplayName("App Store")

            WrongPlatformView(store: .amazon)
                .previewDisplayName("Amazon")

            WrongPlatformView(store: .rcBilling)
                .previewDisplayName("RCBilling")
        }

    }

}

#endif

#endif

#endif
