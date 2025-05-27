//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FallbackNoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

/// If fetching the configuration fails (NO_ACTIVE screen is not present) we display this
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FallbackNoSubscriptionsView: View {

    let actionWrapper: CustomerCenterActionWrapper

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject
    private var customerCenterViewModel: CustomerCenterViewModel

    @State
    private var showRestoreAlert: Bool = false

    init(
        customerCenterViewModel: CustomerCenterViewModel,
        actionWrapper: CustomerCenterActionWrapper
    ) {
        self.customerCenterViewModel = customerCenterViewModel
        self.actionWrapper = actionWrapper
    }

    var body: some View {
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                CompatibilityContentUnavailableView(
                    localization[.noSubscriptionsFound],
                    systemImage: "exclamationmark.triangle.fill",
                    description: Text(localization[.tryCheckRestore])
                )
                .padding()
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            Color(colorScheme == .light
                                  ? UIColor.systemBackground
                                  : UIColor.secondarySystemBackground)
                        )
                        .padding(.horizontal)
                        .padding(.top)
                )
                .padding(.bottom, 32)

                restorePurchasesButton
            }
        }
        .dismissCircleButtonToolbarIfNeeded()
        .overlay {
            RestorePurchasesAlert(
                isPresented: $showRestoreAlert,
                actionWrapper: actionWrapper,
                customerCenterViewModel: customerCenterViewModel
            )
        }
    }

    private var restorePurchasesButton: some View {
        Button {
            showRestoreAlert = true
        } label: {
            CompatibilityLabeledContent(localization[.restorePurchases])
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .tint(colorScheme == .dark ? .white : .black)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        FallbackNoSubscriptionsView(
            customerCenterViewModel: CustomerCenterViewModel(uiPreviewPurchaseProvider: MockCustomerCenterPurchases()),
            actionWrapper: CustomerCenterActionWrapper()
        )
    }

}

#endif

#endif
