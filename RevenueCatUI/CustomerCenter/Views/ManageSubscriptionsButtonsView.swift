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
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsButtonsView: View {

    @ObservedObject
    var viewModel: ManageSubscriptionsViewModel

    var loadingPath: CustomerCenterConfigData.HelpPath?

    var body: some View {
        ForEach(self.viewModel.relevantPathsForPurchase, id: \.id) { path in
            ManageSubscriptionButton(path: path, viewModel: self.viewModel)
        }
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct ManageSubscriptionButton: View {

    let path: CustomerCenterConfigData.HelpPath
    let viewModel: ManageSubscriptionsViewModel

    var body: some View {
        AsyncButton(action: {
            await self.viewModel.determineFlow(for: path)
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
