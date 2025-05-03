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
struct ManageSubscriptionsButtonsView<Content: View>: View {

    var relevantPathsForPurchase: [CustomerCenterConfigData.HelpPath]
    let determineFlowForPath: (CustomerCenterConfigData.HelpPath) async -> Void
    @ViewBuilder let label: (CustomerCenterConfigData.HelpPath) -> Content

    var body: some View {
        ForEach(relevantPathsForPurchase, id: \.id) { path in
            ManageSubscriptionButton(
                path: path,
                determineFlowForPath: determineFlowForPath,
                label: label
            )
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct ManageSubscriptionButton<Content: View>: View {

    let path: CustomerCenterConfigData.HelpPath
    let determineFlowForPath: (CustomerCenterConfigData.HelpPath) async -> Void
    let label: (CustomerCenterConfigData.HelpPath) -> Content

    var body: some View {
        AsyncButton(action: {
            await determineFlowForPath(path)
        }, label: {
            label(path)
        })
//        .disabled(self.viewModel.loadingPath != nil)
    }
}

#endif
