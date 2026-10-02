//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ActiveSubscriptionButtonsView.swift
//
//  Created by Facundo Menzella on 19/5/25.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ActiveSubscriptionButtonsView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject
    var viewModel: BaseManageSubscriptionViewModel

    var activePurchaseIdentifier: String?

    var body: some View {
        #if os(macOS)
        macRows
        #else
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.viewModel.relevantPathsForPurchase, id: \.id) { path in
                AsyncButton(action: {
                    await self.handle(path)
                }, label: {
                    if self.viewModel.loadingPath?.id == path.id {
                        if #available(iOS 26.0, *) {
                            TintedProgressView()
                                .padding()
                        } else {
                            TintedProgressView()
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                        }
                    } else {
                        if #available(iOS 26.0, *) {
                            CompatibilityLabeledContent(path.title)
                                .padding()
                        } else {
                            CompatibilityLabeledContent(path.title)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                        }
                    }
                })
                .disabled(self.viewModel.loadingPath != nil)
                .frame(maxWidth: .infinity)

                if path != self.viewModel.relevantPathsForPurchase.last {
                    Divider()
                }
            }
        }
        .applyIfLet(appearance.tintColor(colorScheme: colorScheme), apply: { $0.tint($1)})
        #if compiler(>=5.9)
        .background(Color(colorScheme == .light
                          ? UIColor.systemBackground
                          : UIColor.secondarySystemBackground),
                    in: .rect(cornerRadius: CustomerCenterStylingUtilities.cornerRadius))
        #endif
        #endif
    }

    private func handle(_ path: CustomerCenterConfigData.HelpPath) async {
        let activeProductId = activePurchaseIdentifier ?? viewModel.purchaseInformation?.productIdentifier
        await self.viewModel.handleHelpPath(path, withActiveProductId: activeProductId)
    }

    #if os(macOS)
    /// One row per help path, for the caller to place in a section of the grouped form the Mac
    /// lays the Customer Center out in. Titles take the appearance's tint, as on iOS.
    private var macRows: some View {
        ForEach(self.viewModel.relevantPathsForPurchase, id: \.id) { path in
            AsyncButton(action: {
                await self.handle(path)
            }, label: {
                HStack {
                    Text(path.title)
                        .foregroundStyle(.tint)
                    Spacer(minLength: 0)
                    if self.viewModel.loadingPath?.id == path.id {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            })
            .customerCenterMacRow()
            .disabled(self.viewModel.loadingPath != nil)
        }
        .applyIfLet(appearance.tintColor(colorScheme: colorScheme), apply: { $0.tint($1)})
    }
    #endif
}

#endif
