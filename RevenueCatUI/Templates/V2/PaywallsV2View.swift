//
//  File.swift
//
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs file_length

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class PaywallStateManager: ObservableObject {
    @Published var state: Result<PaywallState, Error>

    init(state: Result<PaywallState, Error>) {
        self.state = state
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallState {

    typealias PackageInfo = (package: Package, promotionalOfferProductCode: String?)

    let componentsConfig: PaywallComponentsData.PaywallComponentsConfig
    let viewModelFactory: ViewModelFactory
    let packageInfos: [PackageInfo]
    let rootViewModel: RootViewModel
    let showZeroDecimalPlacePrices: Bool

    var packages: [Package] {
        self.packageInfos.map(\.package)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallsV2View: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.paywallSource)
    private var paywallSource

    @Environment(\.workflowPackageContext)
    private var workflowPackageContext

    #if DEBUG
    @Environment(\.paywallLoadingOverride)
    private var paywallLoadingOverride: Bool?
    #endif

    @StateObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @StateObject
    private var paywallStateManager: PaywallStateManager

    @StateObject
    private var selectedPackageContext: PackageContext

    private let paywallComponentsData: PaywallComponentsData
    private let uiConfigProvider: UIConfigProvider
    private let offering: Offering
    private let purchaseHandler: PurchaseHandler
    private let workflowDefaultPackage: Package?
    private let workflowPackages: [Package]?
    private let workflowPromoOfferProductCodes: [String: String]?
    private let showZeroDecimalPlacePrices: Bool
    /// This is a configuration value from PaywallsV1, but it's important to include here just in case the
    /// default paywall is shown. This is not used in the success path
    private let displayCloseButton: Bool
    private let onDismiss: () -> Void
    private let closeWorkflowAction: (() -> Void)?
    /// Non-`nil` only when this paywall is a step inside a workflow, carrying whether it is the current step.
    /// Workflow pages stay mounted across navigation, so `paywall_viewed` / `paywall_close` fire on
    /// activation (becoming / ceasing to be the current step) rather than on SwiftUI's view lifecycle.
    /// `nil` keeps the standalone-paywall behavior of tracking on `onAppear` / `onDisappear`.
    private let isActiveWorkflowPage: Bool?
    /// The workflow step's `screen_type` classification, used to gate impression reporting. `nil` for
    /// standalone paywalls and for workflow steps the backend did not tag (see `stepScreenType`).
    private let workflowScreenType: [String]?
    @State
    private var didFinishEligibilityCheck: Bool = {
        #if DEBUG
        // In Xcode Previews and Emerge snapshot runs, the async eligibility check never
        // completes, so default to finished to avoid capturing permanently-redacted snapshots.
        return ProcessInfo.isRunningForPreviews
        #else
        return false
        #endif
    }()

    @State
    private var paywallSessionID: PaywallEvent.SessionID = .init()

    @StateObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    public init(
        paywallComponents: Offering.PaywallComponents,
        offering: Offering,
        purchaseHandler: PurchaseHandler,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        workflowDefaultPackage: Package? = nil,
        workflowPackages: [Package]? = nil,
        workflowPromoOfferProductCodes: [String: String]? = nil,
        displayCloseButton: Bool = false,
        onDismiss: @escaping () -> Void,
        closeWorkflowAction: (() -> Void)? = nil,
        failedToLoadFont: @escaping UIConfigProvider.FailedToLoadFont,
        colorScheme: ColorScheme,
        promoOfferCache: PaywallPromoOfferCache? = nil,
        introEligibilityContext: IntroOfferEligibilityContext? = nil,
        selectedPackageContextOverride: PackageContext? = nil,
        isActiveWorkflowPage: Bool? = nil,
        workflowScreenType: [String]? = nil
    ) {
        let uiConfigProvider = UIConfigProvider(
            uiConfig: paywallComponents.uiConfig,
            failedToLoadFont: failedToLoadFont,
            automaticallyScaleFontSize: paywallComponents.data.automaticallyScaleFontSize
        )

        self.paywallComponentsData = paywallComponents.data
        self.uiConfigProvider = uiConfigProvider
        self.offering = offering
        self.purchaseHandler = purchaseHandler
        self.workflowDefaultPackage = workflowDefaultPackage
        self.workflowPackages = workflowPackages
        self.workflowPromoOfferProductCodes = workflowPromoOfferProductCodes
        self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        self.displayCloseButton = displayCloseButton
        self.onDismiss = onDismiss
        self.closeWorkflowAction = closeWorkflowAction
        self.isActiveWorkflowPage = isActiveWorkflowPage
        self.workflowScreenType = workflowScreenType
        self._paywallPromoOfferCache = .init(wrappedValue: promoOfferCache ?? PaywallPromoOfferCache(
            subscriptionHistoryTracker: purchaseHandler.subscriptionHistoryTracker
        ))
        self._introOfferEligibilityContext = .init(
            wrappedValue: introEligibilityContext ?? .init(introEligibilityChecker: introEligibilityChecker)
        )

        // Step 0: Decide which ComponentsConfig to use (base is default)
        let componentsConfig = paywallComponentsData.componentsConfig.base

        // The creation of the paywall view components can be intensive and should only be executed once.
        // The instantiation of the PaywallStateManager needs to stay in the init of the wrappedValue
        // because StateObject init is an autoclosure that will only get executed once.
        // Note: paywallStateManager.state is created once; if it becomes dynamic, refresh selectedPackageContext.
        let initialState = Self.createPaywallState(
            componentsConfig: componentsConfig,
            componentsLocalizations: paywallComponents.data.componentsLocalizations,
            preferredLocales: purchaseHandler.preferredLocales,
            defaultLocale: paywallComponents.data.defaultLocale,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            introEligibilityChecker: introEligibilityChecker,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            colorScheme: colorScheme
        )
        self._paywallStateManager = .init(
            wrappedValue: .init(state: initialState)
        )

        let selectedPackageContext: PackageContext
        if let override = selectedPackageContextOverride {
            selectedPackageContext = override
        } else if case .success(let paywallState) = initialState {
            selectedPackageContext = Self.makeSelectedPackageContext(
                from: paywallState,
                defaultPackage: Self.effectiveDefaultPackage(
                    pageDefaultPackage: paywallState.viewModelFactory.packageValidator.defaultSelectedPackage,
                    workflowDefaultPackage: workflowDefaultPackage
                ),
                workflowPackages: workflowPackages,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            )
        } else {
            selectedPackageContext = .init(
                package: nil,
                variableContext: .init(packages: [], showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
            )
        }
        self._selectedPackageContext = .init(wrappedValue: selectedPackageContext)
    }

    public var body: some View {
        self.addPaywallModifiers(to:
            VStack(spacing: 0) {
                if let errorInfo = self.paywallComponentsData.errorInfo, !errorInfo.isEmpty {
                    self.defaultPaywallView(
                        warning: .from(error: PaywallFallbackError(
                            // Trim up the error value to not flood the screen with too much content
                            reason: String("\(errorInfo)".prefix(130))
                        ))
                    )
                } else {
                    switch self.paywallStateManager.state {
                    case .success(let paywallState):
                        self.loadedPaywallView(paywallState: paywallState)
                    case .failure(let error):
                        self.defaultPaywallView(warning: .from(error: error))
                    }
                }
            }
        )
    }

    private func loadedPaywallView(paywallState: PaywallState) -> some View {
        let contentLocale = paywallState.rootViewModel.localizationProvider.locale
        let defaultPackage = Self.effectiveDefaultPackage(
            pageDefaultPackage: paywallState.viewModelFactory.packageValidator.defaultSelectedPackage,
            workflowDefaultPackage: self.workflowPackageContext?.selectedPackage ?? self.workflowDefaultPackage
        )
        return LoadedPaywallsV2View(
            introOfferEligibilityContext: introOfferEligibilityContext,
            paywallState: paywallState,
            uiConfigProvider: self.uiConfigProvider,
            selectedPackageContext: self.selectedPackageContext,
            defaultPackage: defaultPackage,
            onDismiss: self.onDismiss,
            closeWorkflowAction: self.closeWorkflowAction
        )
        .environment(\.isPaywallLoading, {
            #if DEBUG
            if let override = self.paywallLoadingOverride { return override }
            #endif
            return !self.didFinishEligibilityCheck
        }())
        .environment(\.locale, contentLocale)
        .environment(\.layoutDirection, contentLocale.swiftUILayoutDirection)
        .environment(\.screenCondition, ScreenCondition.from(self.horizontalSizeClass))
        .environmentObject(self.purchaseHandler)
        .environmentObject(self.introOfferEligibilityContext)
        .environmentObject(self.paywallPromoOfferCache)
    }

    @ViewBuilder
    private func addCloseButtonIfNeeded<Content: View>(to content: Content) -> some View {
        if self.displayCloseButton {
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Spacer()
                        self.makeCloseButton()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
        } else {
            content
        }
    }

    private func makeCloseButton() -> some View {
        Button {
            self.onDismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                #if !os(watchOS)
                .background(.ultraThinMaterial, in: Circle())
                #endif
        }
        .buttonStyle(.plain)
        .disabled(self.purchaseHandler.actionInProgress)
        .opacity(
            self.purchaseHandler.actionInProgress
            ? Constants.purchaseInProgressButtonOpacity
            : 1
        )
        .accessibilityLabel("Dismiss")
    }

    private func defaultPaywallView(warning: PaywallWarning) -> some View {
        addCloseButtonIfNeeded(to:
            DefaultPaywallView(
                handler: self.purchaseHandler,
                warning: warning,
                offering: self.offering
            )
        )
    }

    private func addPaywallModifiers<Content: View>(to content: Content) -> some View {
        content
            .onAppear {
                // Standalone paywalls (isActiveWorkflowPage == nil) track `viewed` on view lifecycle.
                // A workflow page mounts already-current, so fire here too; later re-entries are handled
                // by `onChangeOf(self.isActiveWorkflowPage)` below. A page mounted while not current
                // (isActiveWorkflowPage == false) waits until it becomes current.
                guard self.isActiveWorkflowPage != false else { return }
                self.firePaywallImpression()
            }
            .task {
                guard !self.didFinishEligibilityCheck else {
                    return
                }
                if let errorInfo = self.paywallComponentsData.errorInfo, !errorInfo.isEmpty {
                    return
                }
                guard case let .success(paywallState) = self.paywallStateManager.state else {
                    return
                }

                async let introCheck: Void = self.introOfferEligibilityContext.computeEligibility(
                    for: Self.introEligibilityPackages(
                        paywallPackages: paywallState.packages,
                        workflowPackages: self.workflowPackages
                    )
                )
                async let promoCheck: Void = self.paywallPromoOfferCache.computeEligibility(
                    for: Self.promoEligibilityPackageInfos(
                        paywallPackageInfos: paywallState.packageInfos.map {
                            ($0.package, $0.promotionalOfferProductCode)
                        },
                        workflowPackages: self.workflowPackages,
                        workflowPromoOfferProductCodes: self.workflowPromoOfferProductCodes
                    )
                )
                _ = await (introCheck, promoCheck)
                self.didFinishEligibilityCheck = true
            }
            // Note: preferences need to be applied after `.toolbar` call
            .preference(key: PurchaseInProgressPreferenceKey.self,
                        value: self.purchaseHandler.packageBeingPurchased)
            .preference(key: PurchasedResultPreferenceKey.self,
                        value: .init(
                            data: self.purchaseHandler.sessionPurchaseResult,
                            diffKey: (self.purchaseHandler.sessionPurchaseResult?.userCancelled == true) ?
                            self.purchaseHandler.consecutiveCancellationRequestID : nil
                        ))
            .preference(key: RestoredCustomerInfoPreferenceKey.self,
                        value: self.purchaseHandler.restoredCustomerInfo)
            .preference(key: RestoreInProgressPreferenceKey.self,
                        value: self.purchaseHandler.restoreInProgress)
            .preference(key: PurchaseErrorPreferenceKey.self,
                        value: self.purchaseHandler.purchaseError as NSError?)
            .preference(key: RestoreErrorPreferenceKey.self,
                        value: self.purchaseHandler.restoreError as NSError?)
            .disabled(self.purchaseHandler.actionInProgress)
            .onDisappear {
                // Standalone closes on disappear. A workflow page closes here only if it is still the
                // current step at teardown (the step the user dismissed from); pages left earlier are
                // not closed here, their navigation is reported by the workflow-events layer.
                guard self.isActiveWorkflowPage != false else { return }
                self.firePaywallClose()
            }
            .environment(
                \.componentInteractionLogger,
                self.purchaseHandler.componentInteractionLogger(sessionID: self.paywallSessionID)
            )
            .onChangeOf(self.purchaseHandler.hasPurchasedInSession) { hasPurchased in
                guard hasPurchased else { return }

                self.dismissAfterPurchaseCompletionCallbacks()
            }
            .onChangeOf(self.isActiveWorkflowPage) { isActive in
                // Workflow page re-entered (became the current step again). Per the events spec each
                // visit is its own session, so mint a fresh one and fire `viewed` for the new visit.
                // (Never fires for standalone paywalls, whose isActiveWorkflowPage is nil and constant.)
                guard isActive == true else { return }
                let freshSession: PaywallEvent.SessionID = .init()
                self.paywallSessionID = freshSession
                self.firePaywallImpression(sessionID: freshSession)
            }

    }

    /// Whether a workflow step reports paywall events at all (impression and close). Reports when:
    /// standalone, `screen_type` is `nil` (untagged/pre-rollout, preserves prior behavior), or it
    /// contains `paywall`. Suppresses only a present `screen_type` lacking `paywall`.
    ///
    /// Per khepri #21429 only the `single_step_fallback_id` step is tagged `["paywall"]`, so a
    /// fallback-less workflow intentionally reports nothing this release; don't relax `[]` lightly.
    static func shouldReportPaywallImpression(
        isActiveWorkflowPage: Bool?,
        workflowScreenType: [String]?
    ) -> Bool {
        guard isActiveWorkflowPage != nil else { return true }
        guard let screenType = workflowScreenType else { return true }
        return screenType.contains(WorkflowScreenType.paywall)
    }

    private var reportsPaywallImpression: Bool {
        Self.shouldReportPaywallImpression(
            isActiveWorkflowPage: self.isActiveWorkflowPage,
            workflowScreenType: self.workflowScreenType
        )
    }

    private func firePaywallImpression(sessionID: PaywallEvent.SessionID? = nil) {
        // A workflow step the backend did not classify as a paywall reports no paywall events. Clear
        // any active session so a purchase here is unattributed, not charged to the prior paywall step.
        guard self.reportsPaywallImpression else {
            self.purchaseHandler.clearActivePaywallSession()
            return
        }

        let forDefaultPaywall: Bool
        if let errorInfo = self.paywallComponentsData.errorInfo, !errorInfo.isEmpty {
            forDefaultPaywall = true
        } else {
            switch self.paywallStateManager.state {
            case .success:
                forDefaultPaywall = false
            case .failure:
                forDefaultPaywall = true
            }
        }
        self.purchaseHandler.trackPaywallImpression(
            self.createEventData(forDefaultPaywall: forDefaultPaywall, sessionID: sessionID)
        )
    }

    private func firePaywallClose() {
        guard self.reportsPaywallImpression else { return }

        if self.isActiveWorkflowPage == nil {
            // Standalone paywall: close whichever session is active (unchanged behavior).
            self.purchaseHandler.trackPaywallClose()
        } else {
            // Workflow page: close this page's own session, not the globally last-active one.
            self.purchaseHandler.trackPaywallClose(sessionID: self.paywallSessionID)
        }
    }

    private func dismissAfterPurchaseCompletionCallbacks() {
        // Defer dismissal so purchase completion preferences propagate to parent modifiers first.
        DispatchQueue.main.async {
            guard self.purchaseHandler.hasPurchasedInSession else { return }

            self.onDismiss()
        }
    }

    private func createEventData(
        forDefaultPaywall: Bool = false,
        sessionID: PaywallEvent.SessionID? = nil
    ) -> PaywallEvent.Data {
        let compontentsData: PaywallComponentsData
        if forDefaultPaywall {
            // The old default paywall was logged as a default template like this.
            // Until we have a new log event for the new default paywall we need to contiunue
            // logging the events like they used to be for data integrity.
            compontentsData = .init(
                templateName: PaywallData.defaultTemplate.rawValue,
                assetBaseURL: PaywallData.defaultTemplateBaseURL,
                componentsConfig: self.paywallComponentsData.componentsConfig,
                componentsLocalizations: self.paywallComponentsData.componentsLocalizations,
                revision: PaywallData.revisionID,
                defaultLocaleIdentifier: self.paywallComponentsData.defaultLocale
            )
        } else {
            compontentsData = self.paywallComponentsData
        }

        return .init(
            offering: self.offering,
            paywallComponentsData: compontentsData,
            sessionID: sessionID ?? self.paywallSessionID,
            displayMode: .fullScreen,
            locale: .current,
            darkMode: self.colorScheme == .dark,
            source: self.paywallSource
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct LoadedPaywallsV2View: View {

    private let introOfferEligibilityContext: IntroOfferEligibilityContext

    private let paywallState: PaywallState
    private let uiConfigProvider: UIConfigProvider
    private let onDismiss: () -> Void
    private let closeWorkflowAction: (() -> Void)?
    private let defaultPackage: Package?

    @ObservedObject
    private var selectedPackageContext: PackageContext

    init(
        introOfferEligibilityContext: IntroOfferEligibilityContext,
        paywallState: PaywallState,
        uiConfigProvider: UIConfigProvider,
        selectedPackageContext: PackageContext,
        defaultPackage: Package?,
        onDismiss: @escaping () -> Void,
        closeWorkflowAction: (() -> Void)? = nil
    ) {
        self.introOfferEligibilityContext = introOfferEligibilityContext
        self.paywallState = paywallState
        self.uiConfigProvider = uiConfigProvider
        self.selectedPackageContext = selectedPackageContext
        self.defaultPackage = defaultPackage
        self.onDismiss = onDismiss
        self.closeWorkflowAction = closeWorkflowAction
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ComponentsView(
                    componentViewModels: [.root(paywallState.rootViewModel)],
                    onDismiss: self.onDismiss,
                    defaultPackage: self.defaultPackage
                )
                .fixMacButtons()
                .environment(\.closeWorkflowAction, self.closeWorkflowAction ?? self.onDismiss)
            }
            // Used for header image and sticky footer
            .environment(\.safeAreaInsets, proxy.safeAreaInsets)
            .applyIf(
                paywallState.rootViewModel.headerViewModel != nil
                || paywallState.rootViewModel.firstItemIsFullWidthMedia,
                apply: { view in
                view
                    .edgesIgnoringSafeArea(.top)
            })
            .applyIf(paywallState.rootViewModel.stackViewModel.component.size.height == .fill, apply: { view in
                view.frame(maxHeight: .infinity, alignment: paywallState.rootViewModel.frameAlignment)
            })
            .backgroundStyle(
                self.paywallState.componentsConfig.background
                    .asDisplayable(
                        uiConfigProvider: uiConfigProvider,
                        localizationProvider: paywallState.rootViewModel.localizationProvider
                    ),
                alignment: .top
            )
            .environment(\.selectedPackageId, self.selectedPackageContext.package?.identifier)
            .environment(\.planSelectionDefaultPackage, self.defaultPackage)
            .environmentObject(self.selectedPackageContext)
            .edgesIgnoringSafeArea(.bottom)
        }
    }

}

/// Custom EnvironmentKey for safe area insets
private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallsV2View {

    // swiftlint:disable:next function_parameter_count
    static func createPaywallState(
        componentsConfig: PaywallComponentsData.PaywallComponentsConfig,
        componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
        preferredLocales: [Locale],
        defaultLocale: String,
        uiConfigProvider: UIConfigProvider,
        offering: Offering,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        colorScheme: ColorScheme
    ) -> Result<PaywallState, Error> {
        // Step 1: Get localization
        let localizationProvider = Self.chooseLocalization(
            componentsLocalizations: componentsLocalizations,
            preferredLocales: preferredLocales,
            defaultLocale: defaultLocale
        )

        do {
            var factory = ViewModelFactory()
            let root = try factory.toRootViewModel(
                componentsConfig: componentsConfig,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                colorScheme: colorScheme
            )

            if factory.discardRules {
                Logger.warning(Strings.paywall_contains_unsupported_condition)
            }

            // WIP: Maybe re-enable this later or add some warnings
//            guard packageValidator.isValid else {
//                Logger.error(Strings.paywall_could_not_find_any_packages)
//                throw PackageGroupValidationError.noAvailablePackages("No available packages found")
//            }

            let packageInfos = factory.packageValidator.packageInfos.map { info in
                return (package: info.package, promotionalOfferProductCode: info.promotionalOfferProductCode)
            }

            return .success(
                .init(
                    componentsConfig: componentsConfig,
                    viewModelFactory: factory,
                    packageInfos: packageInfos,
                    rootViewModel: root,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
                )
            )
        } catch {
            // STEP 2.5: Use fallback paywall if viewmodel construction fails
            Logger.error(Strings.paywall_view_model_construction_failed(error))

            // WIP: Need to select default package in fallback view model
            return .failure(error)
        }
    }

    static func makeSelectedPackageContext(
        from paywallState: PaywallState,
        defaultPackage: Package?,
        workflowPackages: [Package]?,
        showZeroDecimalPlacePrices: Bool
    ) -> PackageContext {
        return .init(
            package: defaultPackage,
            variableContext: .init(
                packages: workflowPackages ?? paywallState.packages,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            )
        )
    }

    static func effectiveDefaultPackage(
        pageDefaultPackage: Package?,
        workflowDefaultPackage: Package?
    ) -> Package? {
        return workflowDefaultPackage ?? pageDefaultPackage
    }

    /// On-screen packages plus any inherited workflow packages, so `intro_offer_condition` overrides
    /// resolve on a workflow step that has no package component of its own.
    static func introEligibilityPackages(
        paywallPackages: [Package],
        workflowPackages: [Package]?
    ) -> [Package] {
        var seen = Set<Package>()
        return (paywallPackages + (workflowPackages ?? [])).filter { seen.insert($0).inserted }
    }

    /// On-screen package infos plus any inherited workflow packages (with their authored promo offer
    /// code), so `promo_offer_condition` overrides resolve on a workflow step that has no package
    /// component of its own.
    static func promoEligibilityPackageInfos(
        paywallPackageInfos: [(package: Package, promotionalOfferProductCode: String?)],
        workflowPackages: [Package]?,
        workflowPromoOfferProductCodes: [String: String]?
    ) -> [(package: Package, promotionalOfferProductCode: String?)] {
        var seen = Set<Package>()
        var result: [(package: Package, promotionalOfferProductCode: String?)] = []
        for info in paywallPackageInfos where seen.insert(info.package).inserted {
            result.append(info)
        }
        for package in workflowPackages ?? [] where seen.insert(package).inserted {
            result.append((package, workflowPromoOfferProductCodes?[package.identifier]))
        }
        return result
    }

    static func chooseLocalization(
        componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
        preferredLocales: [Locale],
        defaultLocale: String
    ) -> LocalizationProvider {

        guard !componentsLocalizations.isEmpty else {
            Logger.error(Strings.paywall_contains_no_localization_data)
            return .init(locale: Locale.current, localizedStrings: PaywallComponent.LocalizationDictionary())
        }

        var notFoundLocales = [Locale]()

        defer {
            if !notFoundLocales.isEmpty {
                let localeStrings = notFoundLocales.map { "\($0)" }
                let msgFormatted = localeStrings.formatted(.list(type: .or))
                Logger.error(Strings.paywall_could_not_find_localization(msgFormatted))
            }
        }

        // STEP 1: Get available paywall locales
        let paywallLocales = componentsLocalizations.keys.map { Locale(identifier: $0) }

        // use default locale as a fallback if none of the user's preferred locales are available in the paywall
        let defaultLocale = Locale(identifier: defaultLocale)

        // STEP 2: choose best locale based on device's list of preferred locales.
        let chosenLocale = Self.preferredLocale(from: paywallLocales, preferredLocales: preferredLocales)
        ?? defaultLocale

        // STEP 3: Get localization for one of preferred locales in order
        if let localizedStrings = componentsLocalizations.findLocale(chosenLocale) {
            return .init(locale: chosenLocale, localizedStrings: localizedStrings)
        } else {
            notFoundLocales.append(chosenLocale)
        }

        if let localizedStrings = componentsLocalizations.findLocale(defaultLocale) {
            return .init(locale: defaultLocale, localizedStrings: localizedStrings)
        } else if !notFoundLocales.contains(defaultLocale) {
            notFoundLocales.append(defaultLocale)
        }

        return .init(locale: defaultLocale, localizedStrings: PaywallComponent.LocalizationDictionary())
    }

    /// Returns the preferred paywall locale from the device's preferred locales.
    ///
    /// The algorithm matches first on language, then on region. If no matching locale is found,
    /// the function returns `nil`.
    ///
    /// - Parameter paywallLocales: An array of `Locale` objects representing the paywall's available locales.
    /// - Parameter preferredLocales: An array of `Locale` objects representing the device's preferred locales.
    /// - Returns: A `Locale` available on the paywall chosen based on the device's preferredlocales,
    /// or `nil` if no match is found.
    ///
    /// # Example 1
    ///   paywall locales: `en_US, fr_FR, en_CA, de_DE`
    ///   preferred locales: `en_CA, en_US, fr_CA`
    ///   returns `en_CA`
    ///
    ///
    /// # Example 2
    ///   paywall locales: `en_US, fr_FR, de_DE`
    ///   preferred locales: `en_CA, en_US, fr_CA`
    ///   returns `en_US`
    ///
    /// # Example 3
    ///   paywall locales: `en_US, fr_FR, de_DE, en_CA`
    ///   preferred locales: `fr_CA, en_CA, en_US`
    ///   returns `fr_FR`
    ///
    /// # Example 4
    ///   paywall locales: `en_US, de_DE`
    ///   preferred locales: `es_ES`
    ///   returns `nil`
    ///
    static func preferredLocale(from paywallLocales: [Locale], preferredLocales: [Locale]) -> Locale? {
        return Locale.selectPreferredLocale(from: paywallLocales, preferredLocales: preferredLocales)
    }

}

private struct PaywallFallbackError: Error {
    let reason: String
}

#endif
