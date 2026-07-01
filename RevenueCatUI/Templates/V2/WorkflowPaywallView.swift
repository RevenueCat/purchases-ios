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
        return self.headerButtonOpacity(for: role, headerTransition: .replacing)
    }

    func headerButtonOpacity(for role: PageRole, headerTransition: WorkflowHeaderTransition) -> CGFloat {
        guard self.isTransitioning else {
            return role == .current ? 1 : 0
        }

        switch headerTransition.mode {
        case .none:
            return role == .current ? 1 : 0
        case .stable:
            return role == .current ? 1 : 0
        case .entering:
            return role == .current ? self.progress : 0
        case .leaving:
            return role == .outgoing ? 1 - self.progress : 0
        case .replacing:
            switch role {
            case .current:
                return self.progress
            case .outgoing:
                return 1 - self.progress
            }
        }
    }

}

struct WorkflowHeaderTransition {

    fileprivate enum Mode {
        case none
        case entering
        case leaving
        case replacing
        case stable
    }

    fileprivate static let replacing = Self(mode: .replacing)

    fileprivate let mode: Mode

    var shouldRenderOverlay: Bool {
        return self.mode != .none
    }

    init<Header: Equatable>(
        currentHeader: Header?,
        outgoingHeader: Header?
    ) {
        switch (currentHeader, outgoingHeader) {
        case (.none, .none):
            self.mode = .none
        case (.some, .none):
            self.mode = .entering
        case (.none, .some):
            self.mode = .leaving
        case let (.some(current), .some(outgoing)) where current == outgoing:
            self.mode = .stable
        case (.some, .some):
            self.mode = .replacing
        }
    }

    private init(mode: Mode) {
        self.mode = mode
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.workflowExitOfferOfferingBinding) private var exitOfferOfferingBinding
    @Environment(\.workflowCompletedInSessionBinding) private var workflowCompletedInSessionBinding

    enum DismissalAction: Equatable {
        case dismissWorkflow
        case navigateBack
    }

    private enum Constants {
        static let transitionDuration: Double = 0.25
        static let transitionStartDelayNanoseconds: UInt64 = 16_000_000
    }

    private let context: WorkflowContext
    private let purchaseHandler: PurchaseHandler
    private let introEligibilityChecker: TrialOrIntroEligibilityChecker
    private let showZeroDecimalPlacePrices: Bool
    private let displayCloseButton: Bool
    private let onDismiss: () -> Void

    @StateObject private var navigator: WorkflowNavigator
    /// One paywall state store per workflow presentation: all screens read and write the same
    /// store, so values survive screen navigation and reset only when the presentation ends
    /// (this view, and with it the `@StateObject`, is torn down). Seeded empty for now —
    /// workflow-root `state` declarations arrive with the workflow wire-format follow-up.
    @StateObject private var stateStore = PaywallStateStore()
    // Held via PromoOfferCacheOwner so this view owns one cache shared across all workflow pages
    // without subscribing to its @Published changes: body only forwards the cache to children.
    // Observing it directly would re-render the whole page ForEach + header overlay on each update.
    @StateObject private var promoOfferCacheOwner: PromoOfferCacheOwner
    @State private var hasLoggedInvalidState = false
    /// Owns the per-impression workflow step event state machine (trace id, fire-once flags, gating).
    /// Created in `init`, so a new presentation (new view identity) yields a fresh `traceId`, matching
    /// Android's per-impression `workflowTraceId`. Its sequence/gating is unit tested in
    /// `WorkflowStepEventCoordinatorTests`.
    @State private var stepEventCoordinator: WorkflowStepEventCoordinator
    @State private var transitionState: WorkflowPageTransitionState<RenderedPage>
    @State private var activeTransitionID: UUID?
    @State private var hasCompletedWorkflowInSession = false
    /// Every step the user has seen, in first-seen order. Each page is kept mounted so its subtree,
    /// and the state it owns (a tab/toggle selection, the `PackageContext` that `PaywallsV2View`
    /// mutates by reference), survives navigating away and back. Also the per-step page cache:
    /// revisiting a step reuses its existing instance, preserving its SwiftUI identity.
    @State private var seenPages: [RenderedPage]

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
        self.onDismiss = onDismiss
        self._navigator = .init(wrappedValue: WorkflowNavigator(workflow: context.workflow))
        self._promoOfferCacheOwner = .init(wrappedValue: PromoOfferCacheOwner(
            cache: promoOfferCache ?? PaywallPromoOfferCache(
                subscriptionHistoryTracker: purchaseHandler.subscriptionHistoryTracker
            )
        ))
        let initialStepId = context.workflow.initialStepId
        let initialPackageInput = Self.buildPackageInput(
            stepId: initialStepId,
            context: context,
            preferredPackage: nil,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
        )
        let initialPage = Self.renderedPage(
            from: context,
            stepId: initialStepId,
            showCloseButton: displayCloseButton,
            introEligibilityChecker: introEligibilityChecker,
            packageInput: initialPackageInput
        )
        self._stepEventCoordinator = .init(
            wrappedValue: WorkflowStepEventCoordinator(
                workflow: context.workflow,
                sink: { [purchaseHandler] event in purchaseHandler.track(event) }
            )
        )
        self._seenPages = .init(wrappedValue: initialPage.map { [$0] } ?? [])
        self._transitionState = .init(wrappedValue: .init(currentPage: initialPage))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Render every seen page keyed by its stable per-step snapshot ID so SwiftUI
                // preserves each subtree's identity (and the state it owns) across navigation.
                // The current and outgoing pages animate; the rest stay mounted but hidden
                // off-screen, non-interactive.
                ForEach(self.seenPages) { page in
                    self.seenPageView(for: page, proxy: proxy)
                }

                self.workflowHeaderOverlay(proxy: proxy)
                    .zIndex(2)

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
            .transitionClipMask(proxy: proxy)
        }
        .allowsHitTesting(!self.transitionState.isTransitioning)
        .workflowTransitionAnimationCompletion(
            progress: self.transitionState.progress,
            activeTransitionID: self.activeTransitionID,
            completion: self.finishTransition
        )
        .task(id: self.activeTransitionID) {
            guard let activeTransitionID = self.activeTransitionID else {
                return
            }

            await self.animateTransition(id: activeTransitionID)
        }
        // Re-emitted on every step change because navigator is @StateObject with @Published
        // currentStepId. The exit offer is resolved synchronously from allOfferings on the
        // triggering step; when the user navigates away the value becomes nil, clearing
        // exitOfferOffering — matching Android's shouldTriggerExitOfferForCurrentStep guard.
        .preference(
            key: WorkflowExitOfferPreferenceKey.self,
            value: Self.exitOfferContext(for: self.context, currentStepId: self.navigator.currentStepId)
        )
        // Write the exit offer directly via the binding injected by PresentingPaywallModifier.
        // This is more reliable than the preference key when the workflow is inside a sheet,
        // since preferences don't always propagate across presentation boundaries.
        // Must use exitOfferContext(for:currentStepId:), not context.exitOfferOffering, because
        // exitOfferOffering is not step-aware — it is non-nil for any step whenever configured.
        .onAppear {
            self.syncExitOfferBinding()
            self.stepEventCoordinator.trackInitialStep(
                self.navigator.currentStep,
                hasRenderedPage: self.transitionState.currentPage != nil
            )
        }
        // Terminal `stepCompleted` is anchored here, mirroring how `paywall_close` is tracked on
        // PaywallsV2View.onDisappear. This is the single dismissal signal that catches every path the
        // workflow can go away — close button, post-purchase auto-dismiss, swipe-to-dismiss on a sheet,
        // and programmatic parent dismiss — without firing during inner step transitions (the outer
        // view stays mounted while pages swap).
        .onDisappear {
            // Workflow abandonment: fires unless the workflow completed naturally before dismissal.
            // The completion signal is explicit because UIKit can reset PurchaseHandler before this
            // view disappears, and restore only completes a workflow when the presenter actually
            // closes it.
            self.stepEventCoordinator.trackAbandonment(
                currentStep: self.navigator.currentStep,
                hasRenderedPage: self.transitionState.currentPage != nil,
                hasCompletedInSession: Self.hasCompletedInSession(
                    hasPurchasedInSession: self.purchaseHandler.hasPurchasedInSession,
                    hasCompletedWorkflowInSession: self.hasCompletedWorkflowInSession ||
                        self.workflowCompletedInSessionBinding.wrappedValue
                )
            )
            self.stepEventCoordinator.trackTerminalCompletion(
                currentStep: self.navigator.currentStep,
                hasRenderedPage: self.transitionState.currentPage != nil
            )
        }
        .onChangeOf(self.navigator.currentStepId) { _ in
            self.syncExitOfferBinding()
        }
        // Workflow-level injection: every page (current, outgoing, and hidden-but-mounted) shares
        // this presentation session's state store. PaywallsV2View only creates its own store when
        // no store was injected from above (i.e. standalone presentation).
        .environment(\.paywallStateStore, self.stateStore)
        // Republish the shared store's snapshot to the whole workflow subtree. This view observes
        // `stateStore` via `@StateObject`, so a state update re-runs this body and refreshes the
        // values every page reads when re-resolving `state` conditions.
        .environment(\.paywallStateValues, self.stateStore.values)
        .environment(\.paywallStateDefaults, self.stateStore.defaults)
    }

    // MARK: - Helpers

    private var displayedPages: [DisplayedPage] {
        return [
            self.transitionState.outgoingPage.map { .init(role: .outgoing, page: $0) },
            self.transitionState.currentPage.map { .init(role: .current, page: $0) }
        ]
        .compactMap { $0 }
    }

    private var headerTransition: WorkflowHeaderTransition {
        return .init(
            currentHeader: self.transitionState.currentPage?.headerComponent,
            outgoingHeader: self.transitionState.outgoingPage?.headerComponent
        )
    }

    private var shouldRenderWorkflowHeaderOverlay: Bool {
        return self.transitionState.isTransitioning && self.headerTransition.shouldRenderOverlay
    }

    @ViewBuilder
    private func seenPageView(for page: RenderedPage, proxy: GeometryProxy) -> some View {
        // current and outgoing animate; every other seen page stays mounted but hidden off-screen
        // so its state is preserved until the user returns to it.
        let isCurrent = page.id == self.transitionState.currentPage?.id
        let isOutgoing = page.id == self.transitionState.outgoingPage?.id
        let isHidden = !isCurrent && !isOutgoing
        let transitionRole: WorkflowPageTransitionState<RenderedPage>.PageRole =
            isOutgoing ? .outgoing : .current
        let pageOffset = isHidden ? 0 : self.transitionState.offset(for: transitionRole, width: proxy.size.width)

        self.pageView(for: page, isActive: isCurrent)
            .environment(
                \.workflowRenderingContext,
                WorkflowRenderingContext(
                    pageTransition: .init(
                        pageOffset: pageOffset,
                        headerButtonOpacity: isHidden
                            ? 0
                            : self.transitionState.headerButtonOpacity(
                                for: transitionRole,
                                headerTransition: self.headerTransition
                            ),
                        // Hidden pages are not part of the animation; only the current/outgoing
                        // pair should see the transition flag so they don't react to it off-screen.
                        isTransitioning: isHidden ? false : self.transitionState.isTransitioning
                    ),
                    pageHeaderSuppressed: self.shouldRenderWorkflowHeaderOverlay
                )
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
            .transitionClipMask(proxy: proxy)
            .opacity(isHidden ? 0 : 1)
            .offset(x: pageOffset)
            .zIndex(isHidden ? -1 : self.transitionState.zIndex(for: transitionRole))
            .allowsHitTesting(!isHidden)
            .accessibilityHidden(isHidden)
    }

    private func pageView(for page: RenderedPage, isActive: Bool) -> some View {
        PaywallsV2View(
            paywallComponents: page.content.paywallComponents,
            offering: page.content.offering,
            purchaseHandler: self.purchaseHandler,
            introEligibilityChecker: self.introEligibilityChecker,
            showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices,
            workflowDefaultPackage: page.effectiveWorkflowPackageContext?.selectedPackage,
            workflowPackages: page.effectiveWorkflowPackageContext?.packages,
            workflowPromoOfferProductCodes: page.effectiveWorkflowPackageContext?.promoOfferCodesByPackageId,
            displayCloseButton: page.showCloseButton,
            onDismiss: self.handleDismiss,
            closeWorkflowAction: self.onDismiss,
            failedToLoadFont: self.failedToLoadFont,
            colorScheme: self.colorScheme,
            promoOfferCache: self.promoOfferCacheOwner.cache,
            introEligibilityContext: page.introOfferEligibilityContext,
            selectedPackageContextOverride: page.packageContext,
            // Drives per-visit paywall_viewed / paywall_close: this page is the current workflow step.
            isActiveWorkflowPage: isActive,
            // Gates impression reporting: only steps tagged as paywalls report a paywall impression.
            workflowScreenType: page.screenType,
            // Workflow attribution on the impression event (#7024), orthogonal to the screen_type gate.
            workflowId: self.context.workflow.id,
            stepId: page.stepId
        )
        .environment(\.workflowPackageContext, page.effectiveWorkflowPackageContext)
        .environment(\.workflowTriggerAction, { componentId in
            return self.handleTriggeredNavigation(componentId: componentId)
        })
    }

    @ViewBuilder
    private func workflowHeaderOverlay(proxy: GeometryProxy) -> some View {
        if self.shouldRenderWorkflowHeaderOverlay {
            ZStack(alignment: .top) {
                ForEach(self.displayedPages) { displayedPage in
                    if displayedPage.page.headerComponent != nil {
                        WorkflowHeaderOverlayPageView(
                            page: displayedPage.page,
                            purchaseHandler: self.purchaseHandler,
                            introEligibilityChecker: self.introEligibilityChecker,
                            introOfferEligibilityContext: displayedPage.page.introOfferEligibilityContext,
                            paywallPromoOfferCache: self.promoOfferCacheOwner.cache,
                            showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices,
                            onDismiss: self.handleDismiss,
                            closeWorkflowAction: self.onDismiss,
                            failedToLoadFont: self.failedToLoadFont,
                            colorScheme: self.colorScheme,
                            horizontalSizeClass: self.horizontalSizeClass,
                            headerOpacity: self.transitionState.headerButtonOpacity(
                                for: displayedPage.role,
                                headerTransition: self.headerTransition
                            )
                        )
                        .zIndex(displayedPage.role == .current ? 1 : 0)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .transitionClipMask(proxy: proxy)
            .environment(\.safeAreaInsets, proxy.safeAreaInsets)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
    }

    private func failedToLoadFont(_ fontConfig: UIConfig.FontsConfig) {
        if Purchases.isConfigured {
            Purchases.shared.failedToLoadFontWithConfig(fontConfig)
        }
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
            if self.purchaseHandler.hasPurchasedInSession {
                self.markWorkflowCompletedInSession()
            }
            self.onDismiss()
        case .navigateBack:
            let fromStep = self.navigator.currentStep
            guard let destination = self.navigator.backNavigationDestination,
                  let page = self.renderedPageForBackNavigation(stepId: destination.step.id) else {
                return
            }

            self.navigator.navigateBack()
            self.stepEventCoordinator.trackTransition(
                from: fromStep,
                to: destination.step,
                renderedPageIsNil: false,
                entryReason: .back
            )
            self.startTransition(
                to: page,
                direction: .back
            )
        }
    }

    private func syncExitOfferBinding() {
        self.exitOfferOfferingBinding.wrappedValue = Self.exitOfferContext(
            for: self.context, currentStepId: self.navigator.currentStepId
        )?.exitOfferOffering
    }

    // MARK: - Workflow step event tracking

    // Emission state and gating (trace id, fire-once, "only if a page rendered") live in
    // `WorkflowStepEventCoordinator`, unit tested in `WorkflowStepEventCoordinatorTests`. The view only
    // forwards its lifecycle/navigation signals to the coordinator: initial step on `onAppear`, forward/back
    // in the navigation handlers, and terminal completion on `onDisappear` (the single dismissal signal that
    // catches close, post-purchase auto-dismiss, swipe-to-dismiss, and programmatic parent dismiss). The
    // binding of those four hooks to the coordinator is verified manually in PaywallsTester.

    static func exitOfferContext(
        for context: WorkflowContext,
        currentStepId: String
    ) -> WorkflowExitOfferContext? {
        return context.exitOfferContext(forStepId: currentStepId)
    }

    private func markWorkflowCompletedInSession() {
        self.hasCompletedWorkflowInSession = true
        self.workflowCompletedInSessionBinding.wrappedValue = true
    }

    /// Whether the workflow reached a natural completion (so dismissing it is not an abandonment).
    /// Purchase state is kept as a fallback, while restore-driven completion comes from the presenter
    /// only when restore actually dismisses the workflow.
    static func hasCompletedInSession(
        hasPurchasedInSession: Bool,
        hasCompletedWorkflowInSession: Bool
    ) -> Bool {
        return hasPurchasedInSession || hasCompletedWorkflowInSession
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
        guard !self.transitionState.isTransitioning else {
            return false
        }

        // Capture the step we are leaving before triggerAction mutates the navigator.
        let fromStep = self.navigator.currentStep
        guard let nextStep = self.navigator.triggerAction(componentId: componentId) else {
            return false
        }

        let page = self.renderedPageForForwardNavigation(
            stepId: nextStep.id,
            canNavigateBack: self.navigator.canNavigateBack,
            carryForwardPackage: self.transitionState.currentPage?.packageContext.package
        )

        self.stepEventCoordinator.trackTransition(
            from: fromStep,
            to: nextStep,
            renderedPageIsNil: page == nil,
            entryReason: .forward
        )
        self.startTransition(to: page, direction: .forward)

        return true
    }

    private func startTransition(
        to page: RenderedPage?,
        direction: WorkflowPageTransitionState<RenderedPage>.Direction
    ) {
        if let page, !self.seenPages.contains(where: { $0.stepId == page.stepId }) {
            self.seenPages.append(page)
        }
        self.transitionState.beginTransition(to: page, direction: direction)

        guard self.transitionState.isTransitioning else {
            self.activeTransitionID = nil
            return
        }

        let transitionID = UUID()
        self.activeTransitionID = transitionID
    }

    @MainActor
    private func animateTransition(id transitionID: UUID) async {
        guard self.activeTransitionID == transitionID,
              self.transitionState.isTransitioning else {
            return
        }

        guard !self.reduceMotion else {
            self.transitionState.advanceAnimation()
            self.finishTransition(id: transitionID)
            return
        }

        do {
            // SwiftUI needs one committed frame with both page snapshots at their
            // initial offsets. Starting the animation from the tap handler can skip
            // straight to the final offset, leaving only child component transitions visible.
            try await Task.sleep(nanoseconds: Constants.transitionStartDelayNanoseconds)
        } catch {
            return
        }

        guard self.activeTransitionID == transitionID else {
            return
        }

        withAnimation(.easeInOut(duration: Constants.transitionDuration)) {
            self.transitionState.advanceAnimation()
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
        showCloseButton: Bool,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        packageInput: RenderedPagePackageInput
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
            stepId: stepId,
            content: .init(paywallComponents: paywallComponents, offering: offering),
            screenType: step.stepScreenType,
            headerComponent: screen.componentsConfig.base.header,
            showCloseButton: showCloseButton,
            introOfferEligibilityContext: .init(introEligibilityChecker: introEligibilityChecker),
            packageContext: packageInput.packageContext,
            effectiveWorkflowPackageContext: packageInput.effectiveWorkflowPackageContext
        )
    }

    static func buildPackageInput(
        stepId: String,
        context: WorkflowContext,
        preferredPackage: Package?,
        showZeroDecimalPlacePrices: Bool
    ) -> RenderedPagePackageInput {
        let effective = context.effectivePackageContext(for: stepId, preferring: preferredPackage)

        guard let effective else {
            return .init(
                packageContext: .init(
                    package: nil,
                    variableContext: .init(packages: [], showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
                ),
                effectiveWorkflowPackageContext: nil
            )
        }

        return .init(
            packageContext: .init(
                package: effective.selectedPackage,
                variableContext: .init(
                    packages: effective.packages,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
                )
            ),
            effectiveWorkflowPackageContext: effective
        )
    }

    private func renderedPageForBackNavigation(stepId: String) -> RenderedPage? {
        // Back navigation always targets a previously-seen step, so its page is already mounted.
        // Returning that same instance keeps its subtree (and the state it owns) intact.
        guard let seenPage = self.seenPages.first(where: { $0.stepId == stepId }) else {
            Logger.error(
                Strings.workflow_paywall_invalid_state(
                    currentStepId: stepId,
                    screenId: self.context.workflow.steps[stepId]?.screenId
                )
            )
            return nil
        }

        return seenPage
    }

    private func renderedPageForForwardNavigation(
        stepId: String,
        canNavigateBack: Bool,
        carryForwardPackage: Package?
    ) -> RenderedPage? {
        // Revisiting a seen step reuses its existing page so SwiftUI keeps the subtree (and the
        // state it owns, e.g. a tab/toggle selection) instead of rebuilding it.
        if let seenPage = self.seenPages.first(where: { $0.stepId == stepId }) {
            return seenPage
        }

        return Self.renderedPage(
            from: self.context,
            stepId: stepId,
            showCloseButton: !canNavigateBack && self.displayCloseButton,
            introEligibilityChecker: self.introEligibilityChecker,
            packageInput: Self.buildPackageInput(
                stepId: stepId,
                context: self.context,
                preferredPackage: carryForwardPackage,
                showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices
            )
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
    let stepId: String
    let content: CurrentStepContent
    /// The step's `screen_type` classification (`nil` when the backend did not tag it). Drives whether
    /// this page reports a paywall impression. See `PaywallsV2View.shouldReportPaywallImpression`.
    let screenType: [String]?
    let headerComponent: PaywallComponent.HeaderComponent?
    let showCloseButton: Bool
    /// Page-scoped so late async eligibility checks cannot overwrite another workflow step.
    let introOfferEligibilityContext: IntroOfferEligibilityContext
    let packageContext: PackageContext
    let effectiveWorkflowPackageContext: WorkflowPackageContext?
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class WorkflowHeaderOverlayStateManager: ObservableObject {
    let state: Result<PaywallState, Error>

    init(state: Result<PaywallState, Error>) {
        self.state = state
    }
}

/// Rebuilds a full `PaywallState` purely to render the page's header in the transition overlay.
/// This is heavier than reusing the page's own state, but it only lives for the duration of a
/// page transition, so the cost is bounded and not on the steady-state render path.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowHeaderOverlayPageView: View {

    @StateObject private var stateManager: WorkflowHeaderOverlayStateManager

    private let page: RenderedPage
    private let purchaseHandler: PurchaseHandler
    private let introOfferEligibilityContext: IntroOfferEligibilityContext
    private let paywallPromoOfferCache: PaywallPromoOfferCache
    private let uiConfigProvider: UIConfigProvider
    private let onDismiss: () -> Void
    private let closeWorkflowAction: () -> Void
    private let horizontalSizeClass: UserInterfaceSizeClass?
    private let headerOpacity: CGFloat

    init(
        page: RenderedPage,
        purchaseHandler: PurchaseHandler,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        introOfferEligibilityContext: IntroOfferEligibilityContext,
        paywallPromoOfferCache: PaywallPromoOfferCache,
        showZeroDecimalPlacePrices: Bool,
        onDismiss: @escaping () -> Void,
        closeWorkflowAction: @escaping () -> Void,
        failedToLoadFont: @escaping UIConfigProvider.FailedToLoadFont,
        colorScheme: ColorScheme,
        horizontalSizeClass: UserInterfaceSizeClass?,
        headerOpacity: CGFloat
    ) {
        let paywallComponents = page.content.paywallComponents
        let uiConfigProvider = UIConfigProvider(
            uiConfig: paywallComponents.uiConfig,
            failedToLoadFont: failedToLoadFont,
            automaticallyScaleFontSize: paywallComponents.data.automaticallyScaleFontSize
        )

        self.page = page
        self.purchaseHandler = purchaseHandler
        self.introOfferEligibilityContext = introOfferEligibilityContext
        self.paywallPromoOfferCache = paywallPromoOfferCache
        self.uiConfigProvider = uiConfigProvider
        self.onDismiss = onDismiss
        self.closeWorkflowAction = closeWorkflowAction
        self.horizontalSizeClass = horizontalSizeClass
        self.headerOpacity = headerOpacity
        self._stateManager = .init(
            wrappedValue: .init(
                state: PaywallsV2View.createPaywallState(
                    componentsConfig: paywallComponents.data.componentsConfig.base,
                    componentsLocalizations: paywallComponents.data.componentsLocalizations,
                    preferredLocales: purchaseHandler.preferredLocales,
                    defaultLocale: paywallComponents.data.defaultLocale,
                    uiConfigProvider: uiConfigProvider,
                    offering: page.content.offering,
                    introEligibilityChecker: introEligibilityChecker,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
                    colorScheme: colorScheme
                )
            )
        )
    }

    var body: some View {
        switch self.stateManager.state {
        case .success(let paywallState):
            self.headerView(paywallState: paywallState)
        case .failure:
            EmptyView()
        }
    }

    @ViewBuilder
    private func headerView(paywallState: PaywallState) -> some View {
        if let headerViewModel = paywallState.rootViewModel.headerViewModel {
            let contentLocale = paywallState.rootViewModel.localizationProvider.locale
            let defaultPackage = PaywallsV2View.effectiveDefaultPackage(
                pageDefaultPackage: paywallState.viewModelFactory.packageValidator.defaultSelectedPackage,
                workflowDefaultPackage: self.page.effectiveWorkflowPackageContext?.selectedPackage
            )

            HeaderComponentView(
                viewModel: headerViewModel,
                onDismiss: self.onDismiss
            )
            .fixedSize(horizontal: false, vertical: true)
            .fixMacButtons()
            .frame(maxWidth: .infinity, alignment: .top)
            .opacity(self.headerOpacity)
            .environment(\.locale, contentLocale)
            .environment(\.layoutDirection, contentLocale.swiftUILayoutDirection)
            .environment(\.screenCondition, ScreenCondition.from(self.horizontalSizeClass))
            .environment(\.selectedPackageId, self.page.packageContext.package?.identifier)
            .environment(\.planSelectionDefaultPackage, defaultPackage)
            .environment(\.workflowPackageContext, self.page.effectiveWorkflowPackageContext)
            .environment(\.closeWorkflowAction, self.closeWorkflowAction)
            .environment(
                \.workflowRenderingContext,
                WorkflowRenderingContext(
                    pageTransition: .init(pageOffset: 0, headerButtonOpacity: 1, isTransitioning: true)
                )
            )
            .environmentObject(self.purchaseHandler)
            .environmentObject(self.introOfferEligibilityContext)
            .environmentObject(self.paywallPromoOfferCache)
            .environmentObject(self.page.packageContext)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RenderedPagePackageInput {
    let packageContext: PackageContext
    let effectiveWorkflowPackageContext: WorkflowPackageContext?
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension View {

    // Keep workflow transitions clipped horizontally, but let page backgrounds render into safe areas.
    // Pages already ignore the bottom safe area, but this GeometryReader is laid out inside the
    // safe-area bounds. A plain `.clipped()` trims that page overflow and exposes the presenting view.
    func transitionClipMask(proxy: GeometryProxy) -> some View {
        self.mask(alignment: .top) {
            Rectangle()
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                )
                .offset(y: -proxy.safeAreaInsets.top)
        }
    }

    func workflowTransitionAnimationCompletion(
        progress: CGFloat,
        activeTransitionID: UUID?,
        completion: @escaping (UUID) -> Void
    ) -> some View {
        self.modifier(
            WorkflowAnimationCompletionModifier(
                progress: progress,
                activeTransitionID: activeTransitionID,
                completion: completion
            )
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowAnimationCompletionModifier: AnimatableModifier {

    // SwiftUI sets transitionState.progress to 1 immediately when the animation starts, but the
    // rendered value reaches 1 only after interpolation completes. Keep the outgoing page alive
    // until this animatable modifier observes the rendered progress finish; using a fixed delay
    // can race with animation timing and drop the outgoing subtree early, which causes flashes.
    var progress: CGFloat
    let activeTransitionID: UUID?
    let completion: (UUID) -> Void

    var animatableData: CGFloat {
        get { self.progress }
        set {
            self.progress = newValue
            self.notifyCompletionIfFinished()
        }
    }

    func body(content: Content) -> some View {
        content
    }

    private func notifyCompletionIfFinished() {
        guard self.progress >= 1,
              let activeTransitionID = self.activeTransitionID else {
            return
        }

        let completion = self.completion
        DispatchQueue.main.async {
            completion(activeTransitionID)
        }
    }

}

#endif
