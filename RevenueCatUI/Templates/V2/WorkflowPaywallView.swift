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

/// Screen bounds for workflow page transitions. The `GeometryReader` behind them sits inside the
/// safe area, so the clip mask and the slide distance both come from `screenWidth`. They have to
/// match: a wider mask shows the off-screen page, a narrower one cuts the page off early.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowTransitionGeometry {

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    /// The whole screen. `size.width` is only the safe-area box the pages lay out in.
    var screenWidth: CGFloat {
        return self.size.width + self.safeAreaInsets.leading + self.safeAreaInsets.trailing
    }

    /// Grows a mask from the safe-area box out to the whole screen. One value per edge, so it also
    /// works when the insets differ side to side, and in right-to-left layouts.
    var maskPadding: EdgeInsets {
        return EdgeInsets(
            top: -self.safeAreaInsets.top,
            leading: -self.safeAreaInsets.leading,
            bottom: -self.safeAreaInsets.bottom,
            trailing: -self.safeAreaInsets.trailing
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowPaywallView: View {

    private enum PresentationState {
        case active
        case failing(error: NSError)
        // The alert clears its error before dismissing, but the presentation must remain failed so
        // an exit offer cannot be restored during dismissal.
        case failureReported

        var error: NSError? {
            guard case let .failing(error) = self else { return nil }
            return error
        }

        var hasFailed: Bool {
            switch self {
            case .active:
                return false
            case .failing, .failureReported:
                return true
            }
        }

        var canReportPresentationError: Bool {
            guard case .failureReported = self else { return true }
            return false
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.workflowExitOfferOfferingBinding) private var exitOfferOfferingBinding
    @Environment(\.workflowCompletedInSessionBinding) private var workflowCompletedInSessionBinding
    @Environment(\.workflowDismissalObserver) private var workflowDismissalObserver

    enum DismissalAction: Equatable {
        case dismissWorkflow
        case navigateBack
    }

    enum BackNavigationResolution: Equatable {
        case navigateWithinWorkflow
        case dismiss(WorkflowDismissalReason)
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
    private let onPresentationError: ((NSError) -> Void)?

    @StateObject private var navigator: WorkflowNavigator
    /// One paywall state store per workflow presentation: all screens read and write the same
    /// store, so values survive screen navigation and reset only when the presentation ends
    /// (this view, and with it the `@StateObject`, is torn down). Seeded from every screen's
    /// declarations: `PaywallsV2View` suppresses its own store inside a workflow, so nothing else
    /// seeds this one.
    @StateObject private var stateStore: PaywallStateStore
    // Held via PromoOfferCacheOwner so this view owns one cache shared across all workflow pages
    // without subscribing to its @Published changes: body only forwards the cache to children.
    // Observing it directly would re-render the whole page ForEach + header overlay on each update.
    @StateObject private var promoOfferCacheOwner: PromoOfferCacheOwner
    @State private var presentationState: PresentationState
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
        onDismiss: @escaping () -> Void,
        onPresentationError: ((NSError) -> Void)? = nil
    ) {
        self.context = context
        self.purchaseHandler = purchaseHandler
        self.introEligibilityChecker = introEligibilityChecker
        self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        self.displayCloseButton = displayCloseButton
        self.onDismiss = onDismiss
        self.onPresentationError = onPresentationError
        self._navigator = .init(wrappedValue: WorkflowNavigator(workflow: context.workflow))
        self._stateStore = .init(
            wrappedValue: PaywallStateStore(declarations: Self.mergedStateDeclarations(in: context.workflow))
        )
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
        let initialPresentationError = Self.presentationError(for: initialStepId, in: context)
        let initialPage = initialPresentationError == nil
            ? Self.renderedPage(
                from: context,
                stepId: initialStepId,
                showCloseButton: displayCloseButton,
                introEligibilityChecker: introEligibilityChecker,
                packageInput: initialPackageInput
            )
            : nil
        self._presentationState = .init(
            initialValue: initialPresentationError.map {
                .failing(error: $0)
            } ?? .active
        )
        self._stepEventCoordinator = .init(
            wrappedValue: WorkflowStepEventCoordinator(
                workflow: context.workflow,
                workflowBlobRef: context.workflowBlobRef,
                sink: { [purchaseHandler] event in purchaseHandler.track(event) }
            )
        )
        self._seenPages = .init(wrappedValue: initialPage.map { [$0] } ?? [])
        self._transitionState = .init(wrappedValue: .init(currentPage: initialPage))
    }

    /// Merged across all screens so a key declared on a screen the user has not reached yet is
    /// already seeded; sorted by id so a key two screens declare differently resolves the same way
    /// every time.
    static func mergedStateDeclarations(
        in workflow: PublishedWorkflow
    ) -> [String: PaywallComponent.StateDeclaration] {
        var merged: [String: PaywallComponent.StateDeclaration] = [:]
        for (_, screen) in workflow.screens.sorted(by: { $0.key < $1.key }) {
            merged.merge(screen.stateDeclarations ?? [:]) { first, _ in first }
        }
        return merged
    }

    var body: some View {
        GeometryReader { proxy in
            let geometry = WorkflowTransitionGeometry(
                size: proxy.size,
                safeAreaInsets: proxy.safeAreaInsets
            )
            ZStack {
                // Render every seen page keyed by its stable per-step snapshot ID so SwiftUI
                // preserves each subtree's identity (and the state it owns) across navigation.
                // The current and outgoing pages animate; the rest stay mounted but hidden
                // off-screen, non-interactive.
                ForEach(self.seenPages) { page in
                    self.seenPageView(for: page, geometry: geometry)
                }

                self.workflowHeaderOverlay(geometry: geometry)
                    .zIndex(2)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Window size for window size condition evaluation (e.g. the
            // workflow header, which renders outside PaywallsV2View's own
            // measurement).
            .environment(\.paywallWindowSize, proxy.size)
            .transitionClipMask(geometry: geometry)
        }
        .allowsHitTesting(!self.transitionState.isTransitioning && !self.presentationState.hasFailed)
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
            value: self.presentationState.hasFailed
                ? nil
                : Self.exitOfferContext(for: self.context, currentStepId: self.navigator.currentStepId)
        )
        // Write the exit offer directly via the binding injected by PresentingPaywallModifier.
        // This is more reliable than the preference key when the workflow is inside a sheet,
        // since preferences don't always propagate across presentation boundaries.
        // Must use exitOfferContext(for:currentStepId:), not context.exitOfferOffering, because
        // exitOfferOffering is not step-aware — it is non-nil for any step whenever configured.
        .onAppear {
            switch self.presentationState {
            case .failing:
                self.exitOfferOfferingBinding.wrappedValue = nil
                self.reportPresentationError(for: self.navigator.currentStepId)
                return
            case .failureReported:
                self.exitOfferOfferingBinding.wrappedValue = nil
                return
            case .active:
                break
            }
            self.syncExitOfferBinding()
            self.stepEventCoordinator.trackInitialStep(
                self.navigator.currentStep,
                hasRenderedPage: self.transitionState.currentPage != nil
            )
        }
        // This catches dismissal paths that do not pass through a workflow failure: close button,
        // post-purchase auto-dismiss, swipe-to-dismiss on a sheet, and programmatic parent dismiss.
        // A late configuration failure tracks the same lifecycle immediately before showing its error;
        // the coordinator's fire-once guards prevent this hook from duplicating those events later.
        .onDisappear {
            self.trackCurrentWorkflowLeft()
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
        .displayError(self.workflowPresentationError, onDismiss: self.onDismiss)
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
    private func seenPageView(
        for page: RenderedPage,
        geometry: WorkflowTransitionGeometry
    ) -> some View {
        // current and outgoing animate; every other seen page stays mounted but hidden off-screen
        // so its state is preserved until the user returns to it.
        let isCurrent = page.id == self.transitionState.currentPage?.id
        let isOutgoing = page.id == self.transitionState.outgoingPage?.id
        let isHidden = !isCurrent && !isOutgoing
        let transitionRole: WorkflowPageTransitionState<RenderedPage>.PageRole =
            isOutgoing ? .outgoing : .current
        let pageOffset = Self.pageOffset(
            isHidden: isHidden,
            role: transitionRole,
            transitionState: self.transitionState,
            geometry: geometry
        )

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
                    pageHeaderSuppressed: self.shouldRenderWorkflowHeaderOverlay,
                    canNavigateBack: self.navigator.canNavigateBack
                )
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .transitionClipMask(geometry: geometry)
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
            // Gates paywall events: steps tagged as paywalls report; untagged steps fall back to the
            // single-step-fallback rule.
            workflowScreenType: page.screenType,
            // Workflow purchase attribution, orthogonal to the screen_type gate.
            workflowId: self.context.workflow.id,
            stepId: page.stepId,
            workflowStepType: page.stepType,
            traceId: self.stepEventCoordinator.traceId,
            isWorkflowSingleStepFallback: page.isSingleStepFallback
        )
        .environment(\.workflowPackageContext, page.effectiveWorkflowPackageContext)
        .environment(\.workflowTriggerAction, { componentId in
            return self.handleTriggeredNavigation(componentId: componentId)
        })
        .environment(\.workflowNavigateBackHandler, self.handleNavigateBack)
    }

    @ViewBuilder
    private func workflowHeaderOverlay(geometry: WorkflowTransitionGeometry) -> some View {
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
                            ),
                            canNavigateBack: self.navigator.canNavigateBack
                        )
                        .zIndex(displayedPage.role == .current ? 1 : 0)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .transitionClipMask(geometry: geometry)
            .environment(\.safeAreaInsets, geometry.safeAreaInsets)
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
            guard let destination = self.navigator.backNavigationDestination else {
                return
            }
            guard Self.presentationError(for: destination.step.id, in: self.context) == nil,
                  let page = self.renderedPageForBackNavigation(stepId: destination.step.id) else {
                self.failWorkflowPresentation(for: destination.step.id)
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

    /// A `navigate_back` action dismisses from the initial step. At any deeper step it performs
    /// normal in-workflow navigation.
    private func handleNavigateBack() {
        guard !self.transitionState.isTransitioning else { return }

        switch Self.backNavigationResolution(
            canNavigateBack: self.navigator.canNavigateBack,
            hasPurchasedInSession: self.purchaseHandler.hasPurchasedInSession
        ) {
        case .navigateWithinWorkflow, .dismiss(.close):
            self.handleDismiss()
        case .dismiss(.navigatedBack):
            self.workflowDismissalObserver?(.navigatedBack)
            self.onDismiss()
        }
    }

    static func backNavigationResolution(
        canNavigateBack: Bool,
        hasPurchasedInSession: Bool
    ) -> BackNavigationResolution {
        if canNavigateBack {
            return .navigateWithinWorkflow
        } else if hasPurchasedInSession {
            return .dismiss(.close)
        } else {
            return .dismiss(.navigatedBack)
        }
    }

    private func syncExitOfferBinding() {
        self.exitOfferOfferingBinding.wrappedValue = self.presentationState.hasFailed
            ? nil
            : Self.exitOfferContext(
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

    /// Finishes the current step and, unless purchase or restore completed this presentation, records
    /// workflow abandonment. Called both when the paywall goes away and when a reached step is found to be
    /// unservable.
    private func trackCurrentWorkflowLeft() {
        let hasRenderedPage = self.transitionState.currentPage != nil
        let completedInSession = Self.hasCompletedInSession(
            hasPurchasedInSession: self.purchaseHandler.hasPurchasedInSession,
            hasCompletedWorkflowInSession: self.hasCompletedWorkflowInSession ||
                self.workflowCompletedInSessionBinding.wrappedValue
        )
        self.stepEventCoordinator.trackTerminalCompletion(
            currentStep: self.navigator.currentStep,
            hasRenderedPage: hasRenderedPage
        )
        self.stepEventCoordinator.trackAbandonment(
            currentStep: self.navigator.currentStep,
            hasRenderedPage: hasRenderedPage,
            hasCompletedInSession: completedInSession
        )
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

    /// How far a page moves sideways during a transition. Pages kept off-screen never move.
    static func pageOffset<Page>(
        isHidden: Bool,
        role: WorkflowPageTransitionState<Page>.PageRole,
        transitionState: WorkflowPageTransitionState<Page>,
        geometry: WorkflowTransitionGeometry
    ) -> CGFloat {
        guard !isHidden else {
            return 0
        }

        return transitionState.offset(for: role, width: geometry.screenWidth)
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

        // Resolve and validate the destination before mutating the navigator. A malformed reached
        // step is a configuration error, not a transition to an empty workflow page.
        let fromStep = self.navigator.currentStep
        guard let destination = self.navigator.triggerActionDestination(componentId: componentId) else {
            return false
        }

        guard Self.presentationError(for: destination.step.id, in: self.context) == nil else {
            self.failWorkflowPresentation(for: destination.step.id)
            return true
        }

        guard let page = self.renderedPageForForwardNavigation(
            stepId: destination.step.id,
            canNavigateBack: destination.canNavigateBackAfterNavigation,
            carryForwardPackage: self.transitionState.currentPage?.packageContext.package
        ) else {
            self.failWorkflowPresentation(for: destination.step.id)
            return true
        }

        guard let nextStep = self.navigator.triggerAction(componentId: componentId) else {
            return false
        }

        self.stepEventCoordinator.trackTransition(
            from: fromStep,
            to: nextStep,
            renderedPageIsNil: false,
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
              let screen = context.workflow.screens[screenId] else {
            return nil
        }

        let paywallComponents = WorkflowScreenMapper.toPaywallComponents(
            screen: screen,
            uiConfig: context.uiConfig,
            paywallId: screenId
        )
        let offering = WorkflowContext.renderingOffering(
            baseOffering: context.offering(for: step),
            paywallComponents: paywallComponents
        )

        return .init(
            stepId: stepId,
            content: .init(paywallComponents: paywallComponents, offering: offering),
            stepType: step.type ?? "screen",
            screenType: step.stepScreenType,
            isSingleStepFallback: stepId == context.workflow.singleStepFallbackId,
            headerComponent: screen.componentsConfig.base.header,
            showCloseButton: showCloseButton,
            introOfferEligibilityContext: .init(introEligibilityChecker: introEligibilityChecker),
            packageContext: packageInput.packageContext,
            effectiveWorkflowPackageContext: packageInput.effectiveWorkflowPackageContext
        )
    }

    /// A reached step must have a screen, and any offering it declares must be available, before it is made
    /// current. Steps without an offering are valid content-only pages. This preserves the current page while
    /// presenting a configuration error instead of replacing it with a blank view.
    static func presentationError(for stepId: String, in context: WorkflowContext) -> NSError? {
        guard let step = context.workflow.steps[stepId] else {
            return WorkflowPresentationError.stepNotFound(
                stepID: stepId,
                workflowID: context.workflow.id
            ) as NSError
        }
        guard let screenId = step.screenId else {
            return WorkflowPresentationError.missingScreenIdentifier(
                stepID: step.id,
                workflowID: context.workflow.id
            ) as NSError
        }
        guard context.workflow.screens[screenId] != nil else {
            return WorkflowPresentationError.screenNotFound(
                screenID: screenId,
                workflowID: context.workflow.id
            ) as NSError
        }
        guard let offeringIdentifier = context.workflow.offeringIdentifier(for: step) else {
            return nil
        }
        guard context.offering(for: step) != nil else {
            return WorkflowPresentationError.offeringNotFound(
                offeringID: offeringIdentifier,
                stepID: step.id
            ) as NSError
        }

        return nil
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

    private func failWorkflowPresentation(for stepId: String) {
        guard self.presentationState.canReportPresentationError else { return }

        let error = Self.presentationError(for: stepId, in: self.context) ?? ErrorCode.configurationError as NSError
        self.trackCurrentWorkflowLeft()
        self.exitOfferOfferingBinding.wrappedValue = nil
        self.presentationState = .failing(error: error)
        self.reportPresentationError(for: stepId)
    }

    private var workflowPresentationError: Binding<NSError?> {
        return .init(
            get: { self.presentationState.error },
            set: { error in
                switch (self.presentationState, error) {
                case (_, let error?):
                    self.presentationState = .failing(error: error)
                case (.failing, nil):
                    self.presentationState = .failureReported
                case (.active, nil), (.failureReported, nil):
                    break
                }
            }
        )
    }

    private func reportPresentationError(for stepId: String) {
        guard let error = self.presentationState.error else { return }

        let message = Strings.workflow_paywall_invalid_state(
            currentStepId: stepId,
            screenId: self.context.workflow.steps[stepId]?.screenId
        )
        Logger.error("\(message): \(error.localizedDescription)")
        self.onPresentationError?(error)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct RenderedPage: Identifiable {
    let id = UUID()
    let stepId: String
    let content: CurrentStepContent
    let stepType: String
    /// The step's `screen_type` classification (`nil` when the backend did not tag it). Drives whether
    /// this page reports paywall events. See `PaywallsV2View.shouldTrackPaywallEvents`.
    let screenType: [String]?
    /// Whether this step is the workflow's `singleStepFallbackId`. Only used to gate paywall events on
    /// untagged steps (`nil` `screenType`), restoring the structural fallback-step-only rule.
    let isSingleStepFallback: Bool
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

/// A workflow configuration problem presented to the customer. Its code stays compatible with the SDK
/// configuration error.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum WorkflowPresentationError: Error {

    case stepNotFound(stepID: String, workflowID: String)
    case missingScreenIdentifier(stepID: String, workflowID: String)
    case screenNotFound(screenID: String, workflowID: String)
    case offeringNotFound(offeringID: String, stepID: String)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WorkflowPresentationError: CustomNSError {

    static let errorDomain = ErrorCode.errorDomain
    var errorCode: Int { return ErrorCode.configurationError.rawValue }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.description]
    }

    private var description: String {
        switch self {
        case let .stepNotFound(stepID, workflowID):
            return "Step '\(stepID)' not found in workflow '\(workflowID)'."
        case let .missingScreenIdentifier(stepID, workflowID):
            return "Step '\(stepID)' has no screen_id in workflow '\(workflowID)'."
        case let .screenNotFound(screenID, workflowID):
            return "Screen '\(screenID)' not found in workflow '\(workflowID)'."
        case let .offeringNotFound(offeringID, stepID):
            return "Offering '\(offeringID)' not found for step '\(stepID)'."
        }
    }

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

    @Environment(\.paywallWindowSize)
    private var paywallWindowSize

    @Environment(\.customPaywallVariables)
    private var customVariables

    private let page: RenderedPage
    private let purchaseHandler: PurchaseHandler
    private let introOfferEligibilityContext: IntroOfferEligibilityContext
    private let paywallPromoOfferCache: PaywallPromoOfferCache
    private let uiConfigProvider: UIConfigProvider
    private let onDismiss: () -> Void
    private let closeWorkflowAction: () -> Void
    private let horizontalSizeClass: UserInterfaceSizeClass?
    private let headerOpacity: CGFloat
    private let canNavigateBack: Bool

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
        headerOpacity: CGFloat,
        canNavigateBack: Bool
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
        self.canNavigateBack = canNavigateBack
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
                pageDefaultPackage: paywallState.viewModelFactory.packageValidator.defaultSelectedPackage(
                    in: PackageSelectionContext(
                        condition: ScreenCondition.from(self.horizontalSizeClass),
                        customVariables: self.customVariables,
                        windowSize: self.paywallWindowSize,
                        isEligibleForIntroOffer: { [introOfferEligibilityContext] in
                            introOfferEligibilityContext.isEligible(package: $0)
                        },
                        isEligibleForPromoOffer: { [paywallPromoOfferCache] in
                            paywallPromoOfferCache.isMostLikelyEligible(for: $0)
                        }
                    )
                ),
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
                    pageTransition: .init(pageOffset: 0, headerButtonOpacity: 1, isTransitioning: true),
                    canNavigateBack: self.canNavigateBack
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

    // Clips transitions to the screen, but still lets page backgrounds paint into the safe areas. A
    // plain `.clipped()` would cut those off and show whatever is behind the paywall.
    func transitionClipMask(geometry: WorkflowTransitionGeometry) -> some View {
        self.mask {
            Rectangle()
                .padding(geometry.maskPadding)
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
