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

struct WorkflowPageTransitionState<Page> {

    enum Direction {
        case forward
        case back
    }

    enum PageRole {
        case current
        case outgoing
    }

    private(set) var currentPage: Page?
    private(set) var outgoingPage: Page?
    private(set) var direction: Direction = .forward
    private(set) var progress: CGFloat = 1

    var isTransitioning: Bool {
        return self.outgoingPage != nil
    }

    init(currentPage: Page?) {
        self.currentPage = currentPage
    }

    mutating func beginTransition(to incomingPage: Page?, direction: Direction) {
        self.direction = direction

        guard let currentPage = self.currentPage,
              let incomingPage else {
            self.currentPage = incomingPage
            self.outgoingPage = nil
            self.progress = 1
            return
        }

        self.currentPage = incomingPage
        self.outgoingPage = currentPage
        self.progress = 0
    }

    mutating func advanceAnimation() {
        guard self.isTransitioning else {
            return
        }

        self.progress = 1
    }

    mutating func completeTransition() {
        self.outgoingPage = nil
        self.progress = 1
    }

    func offset(for role: PageRole, width: CGFloat) -> CGFloat {
        guard self.isTransitioning else {
            return 0
        }

        switch role {
        case .current:
            return self.direction.incomingOffset(width: width) * (1 - self.progress)
        case .outgoing:
            return self.direction.outgoingOffset(width: width) * self.progress
        }
    }

    func zIndex(for role: PageRole) -> Double {
        guard self.isTransitioning else {
            return role == .current ? 0 : -1
        }

        switch role {
        case .current:
            return 0
        case .outgoing:
            return 1
        }
    }

    func headerButtonOpacity(for role: PageRole) -> CGFloat {
        guard self.isTransitioning else {
            return role == .current ? 1 : 0
        }

        switch role {
        case .current:
            return self.progress
        case .outgoing:
            return 1 - self.progress
        }
    }

}

private extension WorkflowPageTransitionState.Direction {

    func incomingOffset(width: CGFloat) -> CGFloat {
        switch self {
        case .forward:
            return width
        case .back:
            return -width
        }
    }

    func outgoingOffset(width: CGFloat) -> CGFloat {
        switch self {
        case .forward:
            return -width
        case .back:
            return width
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPaywallView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    enum DismissalAction: Equatable {
        case dismissWorkflow
        case navigateBack
    }

    private enum Constants {
        static let transitionDuration: Double = 0.25
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
    @State private var transitionState: WorkflowPageTransitionState<RenderedPage>
    @State private var activeTransitionID: UUID?

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
        self._transitionState = .init(
            wrappedValue: .init(
                currentPage: Self.renderedPage(
                    from: context,
                    stepId: context.workflow.initialStepId,
                    canNavigateBack: false,
                    displayCloseButton: displayCloseButton
                )
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Keep each rendered page keyed by its snapshot ID so SwiftUI preserves
                // the outgoing subtree when it changes role from current -> outgoing.
                // Recreating that subtree at transition start caused visible flashing.
                ForEach(self.displayedPages) { displayedPage in
                    let pageOffset = self.transitionState.offset(
                        for: displayedPage.role,
                        width: proxy.size.width
                    )

                    self.pageView(for: displayedPage.page)
                        .environment(
                            \.workflowPageTransitionContext,
                            .init(
                                pageOffset: pageOffset,
                                headerButtonOpacity: self.transitionState.headerButtonOpacity(for: displayedPage.role)
                            )
                        )
                        .offset(x: pageOffset)
                        .zIndex(self.transitionState.zIndex(for: displayedPage.role))
                }

                if self.transitionState.currentPage == nil {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                        .onAppear {
                            self.logInvalidWorkflowStateIfNeeded()
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(!self.transitionState.isTransitioning)
        .clipped()
    }

    // MARK: - Helpers

    private var displayedPages: [DisplayedPage] {
        return [
            self.transitionState.outgoingPage.map { .init(role: .outgoing, page: $0) },
            self.transitionState.currentPage.map { .init(role: .current, page: $0) }
        ]
        .compactMap { $0 }
    }

    private func pageView(for page: RenderedPage) -> some View {
        PaywallsV2View(
            paywallComponents: page.content.paywallComponents,
            offering: page.content.offering,
            purchaseHandler: self.purchaseHandler,
            introEligibilityChecker: self.introEligibilityChecker,
            showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices,
            displayCloseButton: page.showCloseButton,
            onDismiss: self.handleDismiss,
            failedToLoadFont: { fontConfig in
                if Purchases.isConfigured {
                    Purchases.shared.failedToLoadFontWithConfig(fontConfig)
                }
            },
            colorScheme: self.colorScheme,
            promoOfferCache: self.promoOfferCache
        )
        .environment(\.workflowTriggerAction, { componentId in
            return self.handleTriggeredNavigation(componentId: componentId)
        })
    }

    private func handleDismiss() {
        guard !self.transitionState.isTransitioning else {
            return
        }

        switch Self.dismissalAction(
            canNavigateBack: self.navigator.canNavigateBack,
            hasPurchasedInSession: self.purchaseHandler.hasPurchasedInSession
        ) {
        case .dismissWorkflow:
            self.onDismiss()
        case .navigateBack:
            guard let previousStep = self.navigator.navigateBack() else {
                return
            }

            self.startTransition(
                to: Self.renderedPage(
                    from: self.context,
                    stepId: previousStep.id,
                    canNavigateBack: self.navigator.canNavigateBack,
                    displayCloseButton: self.displayCloseButton
                ),
                direction: .back
            )
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

    private func handleTriggeredNavigation(componentId: String) -> Bool {
        guard !self.transitionState.isTransitioning,
              let nextStep = self.navigator.triggerAction(componentId: componentId) else {
            return false
        }

        self.startTransition(
            to: Self.renderedPage(
                from: self.context,
                stepId: nextStep.id,
                canNavigateBack: self.navigator.canNavigateBack,
                displayCloseButton: self.displayCloseButton
            ),
            direction: .forward
        )

        return true
    }

    private func startTransition(
        to page: RenderedPage?,
        direction: WorkflowPageTransitionState<RenderedPage>.Direction
    ) {
        self.transitionState.beginTransition(to: page, direction: direction)

        guard self.transitionState.isTransitioning else {
            self.activeTransitionID = nil
            return
        }

        let transitionID = UUID()
        self.activeTransitionID = transitionID

        guard !self.reduceMotion else {
            self.transitionState.advanceAnimation()
            self.finishTransition(id: transitionID)
            return
        }

        DispatchQueue.main.async {
            guard self.activeTransitionID == transitionID else {
                return
            }

            // Wait one run-loop turn so both pages render at their initial offsets
            // before animating progress to the final positions.
            withAnimation(.easeInOut(duration: Constants.transitionDuration)) {
                self.transitionState.advanceAnimation()
            }

            // Schedule cleanup from here so the deadline is relative to when the
            // animation actually starts, not when startTransition was called.
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.transitionDuration) {
                self.finishTransition(id: transitionID)
            }
        }
    }

    private func finishTransition(id: UUID) {
        guard self.activeTransitionID == id else {
            return
        }

        self.transitionState.completeTransition()
        self.activeTransitionID = nil
    }

    private static func renderedPage(
        from context: WorkflowContext,
        stepId: String,
        canNavigateBack: Bool,
        displayCloseButton: Bool
    ) -> RenderedPage? {
        guard let step = context.workflow.steps[stepId],
              let screenId = step.screenId,
              let screen = context.workflow.screens[screenId],
              let offering = context.offering(for: screen.offeringIdentifier) else {
            return nil
        }

        let paywallComponents = WorkflowScreenMapper.toPaywallComponents(
            screen: screen,
            uiConfig: context.workflow.uiConfig
        )

        return .init(
            content: .init(paywallComponents: paywallComponents, offering: offering),
            showCloseButton: !canNavigateBack && displayCloseButton
        )
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
private struct RenderedPage: Identifiable {
    let id = UUID()
    let content: CurrentStepContent
    let showCloseButton: Bool
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DisplayedPage: Identifiable {
    let role: WorkflowPageTransitionState<RenderedPage>.PageRole
    let page: RenderedPage

    var id: UUID { self.page.id }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CurrentStepContent {
    let paywallComponents: Offering.PaywallComponents
    let offering: Offering
}

#endif
