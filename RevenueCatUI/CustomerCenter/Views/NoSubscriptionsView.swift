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

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView: View {

    let configuration: CustomerCenterConfigData

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
        let fallbackDescription = localization.commonLocalizedString(for: .tryCheckRestore)
        let fallbackTitle = localization.commonLocalizedString(for: .noSubscriptionsFound)

        List {
            Section {
                CompatibilityContentUnavailableView(
                    self.configuration.screens[.noActive]?.title ?? fallbackTitle,
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
            }

        }
        .toolbar {
            ToolbarItem(placement: .compatibleTopBarTrailing) {
                DismissCircleButton()
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
