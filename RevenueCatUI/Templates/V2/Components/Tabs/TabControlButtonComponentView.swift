//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentView.swift
//
//  Created by Josh Holtz on 1/9/25.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabControlButtonComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @EnvironmentObject
    private var tabControlContext: TabControlContext

    private let viewModel: TabControlButtonComponentViewModel
    private let onDismiss: () -> Void

    private var selectedState: ComponentViewState {
        return self.tabControlContext.selectedTabId == self.viewModel.component.tabId ? .selected : .default
    }

    init(viewModel: TabControlButtonComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Button {
            self.tabControlContext.selectedTabId = self.viewModel.component.tabId
        } label: {
            StackComponentView(
                viewModel: self.viewModel.stackViewModel,
                onDismiss: self.onDismiss
            )
            .environment(\.componentViewState, self.selectedState)
        }

    }

}

#endif
