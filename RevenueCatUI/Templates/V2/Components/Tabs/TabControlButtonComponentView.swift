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

    @Environment(\.componentInteractionLogger)
    private var componentInteractionLogger

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
            let originTabId = self.tabControlContext.selectedTabId
            let destinationTabId = self.viewModel.component.tabId

            self.tabControlContext.selectedTabId = destinationTabId
            self.trackTabcomponentInteraction(originTabId: originTabId, destinationTabId: destinationTabId)
        } label: {
            StackComponentView(
                viewModel: self.viewModel.stackViewModel,
                onDismiss: self.onDismiss
            )
            .environment(\.componentViewState, self.selectedState)
        }

    }

    private func trackTabcomponentInteraction(originTabId: String, destinationTabId: String) {
        let destinationContextName = self.tabControlContext.contextName(for: destinationTabId)

        _ = self.componentInteractionLogger(.init(
            componentType: .tab,
            componentName: self.tabControlContext.name,
            componentValue: destinationTabId,
            originIndex: self.tabControlContext.index(for: originTabId),
            destinationIndex: self.tabControlContext.index(for: destinationTabId),
            originContextName: self.tabControlContext.contextName(for: originTabId),
            destinationContextName: destinationContextName,
            defaultIndex: self.tabControlContext.defaultTabIndex
        ))
    }

}

#endif
