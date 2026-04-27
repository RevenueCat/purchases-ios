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

    enum DismissalAction: Equatable {
        case dismissWorkflow
        case navigateBack
    }

    private let context: WorkflowContext
    private let purchaseHandler: PurchaseHandler
    private let introEligibilityChecker: TrialOrIntroEligibilityChecker
    private let showZeroDecimalPlacePrices: Bool
    private let displayCloseButton: Bool
    private let promoOfferCache: PaywallPromoOfferCache?
    private let onDismiss: () -> Void

    @StateObject private var navigator: WorkflowNavigator
    @State private var hasLoggedInvalidState = false

    init(
        context: WorkflowContext,
        purchaseHandler: PurchaseHandler,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        displayCloseButton: Bool,
        promoOfferCache: PaywallPromoOfferCache?,
        onDismiss: @escaping () -> Void
    ) {
        self.context = context
        self.purchaseHandler = purchaseHandler
        self.introEligibilityChecker = introEligibilityChecker
        self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        self.displayCloseButton = displayCloseButton
        self.promoOfferCache = promoOfferCache
        self.onDismiss = onDismiss
        self._navigator = .init(wrappedValue: WorkflowNavigator(workflow: context.workflow))
    }

    var body: some View {
        if let stepContent = self.currentStepContent {
            PaywallsV2View(
                paywallComponents: stepContent.paywallComponents,
                offering: stepContent.offering,
                purchaseHandler: self.purchaseHandler,
                introEligibilityChecker: self.introEligibilityChecker,
                showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices,
                displayCloseButton: self.shouldDisplayCloseButton,
                onDismiss: self.handleDismiss,
                failedToLoadFont: { fontConfig in
                    if Purchases.isConfigured {
                        Purchases.shared.failedToLoadFontWithConfig(fontConfig)
                    }
                },
                colorScheme: self.colorScheme,
                promoOfferCache: self.promoOfferCache
            )
            .id(navigator.currentStepId)
            .environment(\.workflowTriggerAction, { componentId in
                self.navigator.triggerAction(componentId: componentId) != nil
            })
        } else {
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
                .onAppear {
                    self.logInvalidWorkflowStateIfNeeded()
                }
        }
    }

    private func handleDismiss() {
        switch Self.dismissalAction(
            canNavigateBack: self.navigator.canNavigateBack,
            hasPurchasedInSession: self.purchaseHandler.hasPurchasedInSession
        ) {
        case .dismissWorkflow:
            onDismiss()
        case .navigateBack:
            navigator.navigateBack()
        }
    }

    static func dismissalAction(
        canNavigateBack: Bool,
        hasPurchasedInSession: Bool
    ) -> DismissalAction {
        guard canNavigateBack, !hasPurchasedInSession else {
            return .dismissWorkflow
        }

        return .navigateBack
    }

    private var shouldDisplayCloseButton: Bool {
        return !self.navigator.canNavigateBack && self.displayCloseButton
    }

    private var currentStepContent: CurrentStepContent? {
        guard let step = self.navigator.currentStep,
              let screenId = step.screenId,
              let screen = self.context.workflow.screens[screenId],
              let offering = self.context.offering(for: screen.offeringIdentifier) else {
            return nil
        }

        let paywallComponents = WorkflowScreenMapper.toPaywallComponents(
            screen: screen,
            uiConfig: self.context.workflow.uiConfig
        )

        return .init(paywallComponents: paywallComponents, offering: offering)
    }

    private func logInvalidWorkflowStateIfNeeded() {
        guard !self.hasLoggedInvalidState else {
            return
        }

        self.hasLoggedInvalidState = true
        Logger.error(
            Strings.workflow_paywall_invalid_state(
                currentStepId: self.navigator.currentStepId,
                screenId: self.navigator.currentStep?.screenId
            )
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CurrentStepContent {
    let paywallComponents: Offering.PaywallComponents
    let offering: Offering
}

#endif
