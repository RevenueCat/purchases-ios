//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPaywallView.swift

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPaywallView: View {

    @Environment(\.colorScheme) private var colorScheme

    private let context: WorkflowContext
    private let onDismiss: () -> Void

    @StateObject private var navigator: WorkflowNavigator
    @StateObject private var purchaseHandler: PurchaseHandler

    init(context: WorkflowContext, onDismiss: @escaping () -> Void) {
        self.context = context
        self.onDismiss = onDismiss
        self._navigator = .init(wrappedValue: WorkflowNavigator(workflow: context.workflow))
        self._purchaseHandler = .init(wrappedValue: .default())
    }

    var body: some View {
        if let step = navigator.currentStep,
           let screenId = step.screenId,
           let screen = context.workflow.screens[screenId] {
            let paywallComponents = WorkflowScreenMapper.toPaywallComponents(
                screen: screen,
                uiConfig: context.workflow.uiConfig
            )
            let offering = screen.offeringIdentifier
                .flatMap { context.allOfferings.all[$0] }
                ?? context.initialOffering

            PaywallsV2View(
                paywallComponents: paywallComponents,
                offering: offering,
                purchaseHandler: self.purchaseHandler,
                introEligibilityChecker: .default(),
                showZeroDecimalPlacePrices: false,
                displayCloseButton: false,
                onDismiss: self.handleDismiss,
                failedToLoadFont: { fontConfig in
                    if Purchases.isConfigured {
                        Purchases.shared.failedToLoadFontWithConfig(fontConfig)
                    }
                },
                colorScheme: self.colorScheme
            )
            .id(navigator.currentStepId)
            .environment(\.workflowTriggerAction, { componentId in
                self.navigator.triggerAction(componentId: componentId) != nil
            })
        }
    }

    private func handleDismiss() {
        if navigator.canNavigateBack {
            navigator.navigateBack()
        } else {
            onDismiss()
        }
    }

}

#endif
