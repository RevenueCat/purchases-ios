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

    private enum Constants {
        static let navBarHeight: CGFloat = 44
        static let navBarSideItemMaxWidth: CGFloat = 128
        static let transitionDuration: Double = 0.25
    }

    private let context: WorkflowContext
    private let purchaseHandler: PurchaseHandler
    private let introEligibilityChecker: TrialOrIntroEligibilityChecker
    private let showZeroDecimalPlacePrices: Bool
    private let promoOfferCache: PaywallPromoOfferCache?
    private let onDismiss: () -> Void

    @StateObject private var navigator: WorkflowNavigator
    @State private var hasLoggedInvalidState = false
    @State private var transitionIsForward: Bool = true
    @State private var leadingItemWidth: CGFloat = 0
    @State private var trailingItemWidth: CGFloat = 0

    init(
        context: WorkflowContext,
        purchaseHandler: PurchaseHandler,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        promoOfferCache: PaywallPromoOfferCache?,
        onDismiss: @escaping () -> Void
    ) {
        self.context = context
        self.purchaseHandler = purchaseHandler
        self.introEligibilityChecker = introEligibilityChecker
        self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        self.promoOfferCache = promoOfferCache
        self.onDismiss = onDismiss
        self._navigator = .init(wrappedValue: WorkflowNavigator(workflow: context.workflow))
    }

    var body: some View {
        VStack(spacing: 0) {
            self.navigationBar

            ZStack {
                if let stepContent = self.currentStepContent {
                    PaywallsV2View(
                        paywallComponents: stepContent.paywallComponents,
                        offering: stepContent.offering,
                        purchaseHandler: self.purchaseHandler,
                        introEligibilityChecker: self.introEligibilityChecker,
                        showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices,
                        displayCloseButton: false,
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
                    .transition(self.pageTransition)
                    .environment(\.workflowTriggerAction, { componentId in
                        self.transitionIsForward = true
                        return self.navigator.triggerAction(componentId: componentId) != nil
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(.easeInOut(duration: Constants.transitionDuration), value: navigator.currentStepId)
        }
    }

    // MARK: - Nav bar

    private var navigationBar: some View {
        ZStack {
            HStack(spacing: 12) {
                self.leadingNavigationItem
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: Constants.navBarSideItemMaxWidth, alignment: .leading)
                    .onWidthChange { self.leadingItemWidth = $0 }

                Spacer(minLength: 0)

                self.trailingNavigationItem
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: Constants.navBarSideItemMaxWidth, alignment: .trailing)
                    .onWidthChange { self.trailingItemWidth = $0 }
            }

            if let title = self.currentScreenName {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, max(self.leadingItemWidth, self.trailingItemWidth) + 12)
            }
        }
        .frame(height: Constants.navBarHeight)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private var leadingNavigationItem: some View {
        if navigator.canNavigateBack {
            Button {
                self.transitionIsForward = false
                self.navigator.navigateBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    if let previousTitle = self.previousScreenName {
                        Text(previousTitle)
                            .font(.system(size: 17))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        } else {
            Button("Close") {
                self.onDismiss()
            }
            .font(.system(size: 17))
            .foregroundStyle(.blue)
            .buttonStyle(.plain)
        }
    }

    private var trailingNavigationItem: some View {
        Button("Close") {
            self.onDismiss()
        }
        .font(.system(size: 17))
        .foregroundStyle(.blue)
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func handleDismiss() {
        switch Self.dismissalAction(
            canNavigateBack: self.navigator.canNavigateBack,
            hasPurchasedInSession: self.purchaseHandler.hasPurchasedInSession
        ) {
        case .dismissWorkflow:
            onDismiss()
        case .navigateBack:
            self.transitionIsForward = false
            self.navigator.navigateBack()
        }
    }

    static func dismissalAction(
        canNavigateBack: Bool,
        hasPurchasedInSession: Bool
    ) -> DismissalAction {
        // After a purchase, always close the whole workflow regardless of back stack —
        // navigating back to a previous step post-purchase would be confusing and
        // could allow the user to purchase again.
        guard canNavigateBack, !hasPurchasedInSession else {
            return .dismissWorkflow
        }

        return .navigateBack
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: transitionIsForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: transitionIsForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var currentScreenName: String? {
        guard let step = navigator.currentStep,
              let screenId = step.screenId else { return nil }
        return context.workflow.screens[screenId]?.name
    }

    private var previousScreenName: String? {
        guard let previousStep = navigator.previousStep,
              let screenId = previousStep.screenId else { return nil }
        return context.workflow.screens[screenId]?.name
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
