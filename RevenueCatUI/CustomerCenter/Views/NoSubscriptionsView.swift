//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

#if CUSTOMER_CENTER_ENABLED

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView: View {

    // swiftlint:disable:next todo
    // TODO: build screen using this configuration
    let configuration: CustomerCenterConfigData

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme
    @State
    private var showRestoreAlert: Bool = false

    init(configuration: CustomerCenterConfigData) {
        self.configuration = configuration
    }

    var body: some View {
        let fallbackDescription = "We can try checking your Apple account for any previous purchases"

        List {
            Section {
                CompatibilityContentUnavailableView(
                    self.configuration.screens[.noActive]?.title ?? "No subscriptions found",
                    systemImage: "exclamationmark.triangle.fill",
                    description:
                        Text(self.configuration.screens[.noActive]?.subtitle ?? fallbackDescription)
                )
            }

            Section {
                Button(localization.commonLocalizedString(for: .restorePurchases)) {
                    showRestoreAlert = true
                }
                .restorePurchasesAlert(isPresented: $showRestoreAlert)
            } header: {
                let subtitle = localization.commonLocalizedString(for: .tryCheckRestore)
                Text(subtitle)
                    .textCase(nil)
            }

        }
        .toolbar {
            ToolbarItem(placement: .compatibleTopBarTrailing) {
                DismissCircleButton {
                    dismiss()
                }
            }
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        NoSubscriptionsView(configuration: CustomerCenterConfigTestData.customerCenterData)
    }

}

#endif

#endif

#endif
