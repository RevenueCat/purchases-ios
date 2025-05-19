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
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ActiveSubscriptionButtonsView: View {

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
                        wihtActiveProductId: viewModel.purchaseInformation?.productIdentifier)
                }, label: {
                    if self.viewModel.loadingPath?.id == path.id {
                        TintedProgressView()
                    } else {
                        CompatibilityLabeledContent(path.title)
                            .padding()
                    }
                })
                .disabled(self.viewModel.loadingPath != nil)
                .frame(maxWidth: .infinity)

                if path != self.viewModel.relevantPathsForPurchase.last {
                    Divider()
                }
            }
        }
        .background(Color(colorScheme == .light
                          ? UIColor.systemBackground
                          : UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

}

#endif
