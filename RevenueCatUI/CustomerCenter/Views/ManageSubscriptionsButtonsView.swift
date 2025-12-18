//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsButtonsView.swift
//
//  Created by Cesar de la Vega on 2/12/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsButtonsView: View {

    @ObservedObject
    var viewModel: BaseManageSubscriptionViewModel

    var body: some View {
        ForEach(self.viewModel.relevantPathsForPurchase, id: \.id) { path in
            ManageSubscriptionButton(
                path: path,
                viewModel: self.viewModel
            )
        }
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct ManageSubscriptionButton: View {

    let path: CustomerCenterConfigData.HelpPath

    @ObservedObject
    var viewModel: BaseManageSubscriptionViewModel

    var body: some View {
        AsyncButton(action: {
            await self.viewModel.handleHelpPath(
                path,
                withActiveProductId: viewModel.purchaseInformation?.productIdentifier)
        }, label: {
            if self.viewModel.loadingPath?.id == path.id {
                TintedProgressView()
            } else {
                Text(path.title)
            }
        })
        .disabled(self.viewModel.loadingPath != nil)
    }

}

#endif
