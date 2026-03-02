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

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ActiveSubscriptionButtonsView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject
    var viewModel: BaseManageSubscriptionViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.viewModel.relevantPathsForPurchase, id: \.id) { path in
                AsyncButton(action: {
                    await self.viewModel.handleHelpPath(
                        path,
                        withActiveProductId: viewModel.purchaseInformation?.productIdentifier)
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
    }
}

#endif
