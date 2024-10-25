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
        let body = supportInformation.calculateBody(self.localization)
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
                    localization.commonLocalizedString(for: .platformMismatch),
                    systemImage: "exclamationmark.triangle.fill",
                    description: Text(platformInstructions)
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
                DismissCircleButton()
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

    private func humanReadableInstructions(for store: Store?) -> String {
        let defaultContactSupport = localization.commonLocalizedString(for: .pleaseContactSupportToManage)

        if let store {
            switch store {
            case .appStore, .macAppStore:
                return localization.commonLocalizedString(for: .appleSubscriptionManage)
            case .playStore:
                return localization.commonLocalizedString(for: .googleSubscriptionManage)
            case .stripe, .rcBilling, .external, .promotional, .unknownStore:
                return defaultContactSupport
            case .amazon:
                return localization.commonLocalizedString(for: .amazonSubscriptionManage)
            }
        } else {
            return defaultContactSupport
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
