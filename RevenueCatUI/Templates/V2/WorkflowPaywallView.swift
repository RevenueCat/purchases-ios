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

    fileprivate var debugName: String {
        switch self.mode {
        case .none:
            return "none"
        case .entering:
            return "entering"
        case .leaving:
            return "leaving"
        case .replacing:
            return "replacing"
        case .stable:
            return "stable"
        }
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
    @StateObject private var introOfferEligibilityContext: IntroOfferEligibilityContext
    @StateObject private var paywallPromoOfferCache: PaywallPromoOfferCache
    @State private var hasLoggedInvalidState = false
    @State private var transitionState: WorkflowPageTransitionState<RenderedPage>
    @State private var activeTransitionID: UUID?
    /// PackageContext is intentionally cached by reference: PaywallsV2View mutates the same
    /// instance, so user selections persist when revisiting a workflow step.
    @State private var stepPackageContexts: [String: PackageContext]

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
        self._introOfferEligibilityContext = .init(
            wrappedValue: .init(introEligibilityChecker: introEligibilityChecker)
        )
        self._paywallPromoOfferCache = .init(wrappedValue: promoOfferCache ?? PaywallPromoOfferCache(
            subscriptionHistoryTracker: purchaseHandler.subscriptionHistoryTracker
        ))
        let initialStepId = context.workflow.initialStepId
        let initialPackageInput = Self.buildPackageInput(
            stepId: initialStepId,
            context: context,
            preferredPackage: nil,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
        )
        self._stepPackageContexts = .init(wrappedValue: [initialStepId: initialPackageInput.packageContext])
        self._transitionState = .init(
            wrappedValue: .init(
                currentPage: Self.renderedPage(
                    from: context,
                    stepId: initialStepId,
                    canNavigateBack: false,
                    displayCloseButton: displayCloseButton,
                    packageInput: initialPackageInput
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
                                headerButtonOpacity: self.transitionState.headerButtonOpacity(
                                    for: displayedPage.role,
                                    headerTransition: self.headerTransition
                                ),
                                isTransitioning: self.transitionState.isTransitioning
                            )
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .transitionClipMask(proxy: proxy)
                        .offset(x: pageOffset)
                        .zIndex(self.transitionState.zIndex(for: displayedPage.role))
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
        }
        .onChangeOf(self.navigator.currentStepId) { _ in
            self.syncExitOfferBinding()
        }
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

    private func pageView(for page: RenderedPage) -> some View {
        PaywallsV2View(
            paywallComponents: page.content.paywallComponents,
            offering: page.content.offering,
            purchaseHandler: self.purchaseHandler,
            introEligibilityChecker: self.introEligibilityChecker,
            showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices,
            workflowDefaultPackage: page.effectiveWorkflowPackageContext?.selectedPackage,
            workflowPackages: page.effectiveWorkflowPackageContext?.packages,
            displayCloseButton: page.showCloseButton,
            onDismiss: self.handleDismiss,
            closeWorkflowAction: self.onDismiss,
            failedToLoadFont: self.failedToLoadFont,
            colorScheme: self.colorScheme,
            promoOfferCache: self.paywallPromoOfferCache,
            introEligibilityContext: self.introOfferEligibilityContext,
            selectedPackageContextOverride: page.packageContext
        )
        .environment(\.workflowPackageContext, page.effectiveWorkflowPackageContext)
        .environment(\.workflowTriggerAction, { componentId in
            return self.handleTriggeredNavigation(componentId: componentId)
        })
        .environment(\.workflowPageHeaderSuppressed, self.shouldRenderWorkflowHeaderOverlay)
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
                            introOfferEligibilityContext: self.introOfferEligibilityContext,
                            paywallPromoOfferCache: self.paywallPromoOfferCache,
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
            .edgesIgnoringSafeArea(.top)
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
            self.onDismiss()
        case .navigateBack:
            guard let destination = self.navigator.backNavigationDestination,
                  let page = self.renderedPageForBackNavigation(
                      stepId: destination.step.id,
                      canNavigateBack: destination.canNavigateBackAfterNavigation
                  ) else {
                return
            }

            self.navigator.navigateBack()
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

    private func logHeaderTransition(stage: String, transitionID: UUID) {
        let headerTransition = self.headerTransition

        Logger.debug(
            Strings.workflow_header_transition(
                stage: stage,
                transitionId: transitionID.uuidString,
                mode: headerTransition.debugName,
                currentHeader: self.transitionState.currentPage?.headerDebugDescription ?? "none",
                outgoingHeader: self.transitionState.outgoingPage?.headerDebugDescription ?? "none",
                progress: self.transitionState.progress.workflowDebugDescription,
                currentOpacity: self.transitionState.headerButtonOpacity(
                    for: .current,
                    headerTransition: headerTransition
                ).workflowDebugDescription,
                outgoingOpacity: self.transitionState.headerButtonOpacity(
                    for: .outgoing,
                    headerTransition: headerTransition
                ).workflowDebugDescription
            )
        )
    }

    static func exitOfferContext(
        for context: WorkflowContext,
        currentStepId: String
    ) -> WorkflowExitOfferContext? {
        return context.exitOfferContext(forStepId: currentStepId)
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
            to: self.renderedPageForForwardNavigation(
                stepId: nextStep.id,
                canNavigateBack: self.navigator.canNavigateBack,
                carryForwardPackage: self.transitionState.currentPage?.packageContext.package
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
        self.logHeaderTransition(stage: "start", transitionID: transitionID)
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

        self.logHeaderTransition(stage: "finish", transitionID: id)
        self.transitionState.completeTransition()
        self.activeTransitionID = nil
    }

    private static func renderedPage(
        from context: WorkflowContext,
        stepId: String,
        canNavigateBack: Bool,
        displayCloseButton: Bool,
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
            content: .init(paywallComponents: paywallComponents, offering: offering),
            headerComponent: screen.componentsConfig.base.header,
            showCloseButton: !canNavigateBack && displayCloseButton,
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

    private func renderedPageForBackNavigation(
        stepId: String,
        canNavigateBack: Bool
    ) -> RenderedPage? {
        guard let packageContext = self.stepPackageContexts[stepId] else {
            Logger.error(
                Strings.workflow_paywall_invalid_state(
                    currentStepId: stepId,
                    screenId: self.context.workflow.steps[stepId]?.screenId
                )
            )
            return nil
        }

        return Self.renderedPage(
            from: self.context,
            stepId: stepId,
            canNavigateBack: canNavigateBack,
            displayCloseButton: self.displayCloseButton,
            packageInput: .init(
                packageContext: packageContext,
                effectiveWorkflowPackageContext: self.context.effectivePackageContext(
                    for: stepId,
                    preferring: packageContext.package
                )
            )
        )
    }

    private func renderedPageForForwardNavigation(
        stepId: String,
        canNavigateBack: Bool,
        carryForwardPackage: Package?
    ) -> RenderedPage? {
        let packageInput: RenderedPagePackageInput
        if let cached = self.stepPackageContexts[stepId] {
            packageInput = .init(
                packageContext: cached,
                effectiveWorkflowPackageContext: self.context.effectivePackageContext(
                    for: stepId,
                    preferring: cached.package
                )
            )
        } else {
            packageInput = Self.buildPackageInput(
                stepId: stepId,
                context: self.context,
                preferredPackage: carryForwardPackage,
                showZeroDecimalPlacePrices: self.showZeroDecimalPlacePrices
            )
            self.stepPackageContexts[stepId] = packageInput.packageContext
        }

        return Self.renderedPage(
            from: self.context,
            stepId: stepId,
            canNavigateBack: canNavigateBack,
            displayCloseButton: self.displayCloseButton,
            packageInput: packageInput
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
    let headerComponent: PaywallComponent.HeaderComponent?
    let showCloseButton: Bool
    let packageContext: PackageContext
    let effectiveWorkflowPackageContext: WorkflowPackageContext?
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension RenderedPage {

    var headerDebugDescription: String {
        guard let headerComponent else {
            return "none"
        }

        let name = headerComponent.stack.name ?? "nil"
        return "stackName=\(name), components=\(headerComponent.stack.components.count), " +
            "hash=\(headerComponent.hashValue)"
    }

}

private extension CGFloat {

    var workflowDebugDescription: String {
        return "\(self)"
    }

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
                \.workflowPageTransitionContext,
                .init(pageOffset: 0, headerButtonOpacity: 1, isTransitioning: true)
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
