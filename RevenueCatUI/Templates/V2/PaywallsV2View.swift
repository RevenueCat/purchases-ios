//
//  File.swift
//
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs file_length

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class PaywallStateManager: ObservableObject {
    @Published var state: Result<PaywallState, Error>

    init(state: Result<PaywallState, Error>) {
        self.state = state
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallState {

    let componentsConfig: PaywallComponentsData.PaywallComponentsConfig
    let viewModelFactory: ViewModelFactory
    let packages: [Package]
    let rootViewModel: RootViewModel
    let showZeroDecimalPlacePrices: Bool

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DataForV1DefaultPaywall {

    let offering: Offering
    let activelySubscribedProductIdentifiers: Set<String>
    let paywall: PaywallData
    let template: PaywallTemplate
    let mode: PaywallViewMode
    let fonts: PaywallFontProvider
    let displayCloseButton: Bool
    let introEligibility: TrialOrIntroEligibilityChecker
    let purchaseHandler: PurchaseHandler
    let locale: Locale
    let showZeroDecimalPlacePrices: Bool

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum FallbackContent {
    case paywallV1View(DataForV1DefaultPaywall)
    case customView(AnyView)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .paywallV1View(let data):
            LoadedOfferingPaywallView(
                offering: data.offering,
                activelySubscribedProductIdentifiers: data.activelySubscribedProductIdentifiers,
                paywall: data.paywall,
                template: data.template,
                mode: data.mode,
                fonts: data.fonts,
                displayCloseButton: data.displayCloseButton,
                introEligibility: data.introEligibility,
                purchaseHandler: data.purchaseHandler,
                locale: data.locale,
                showZeroDecimalPlacePrices: data.showZeroDecimalPlacePrices
            )
        case .customView(let view):
            view
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallsV2View: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.colorScheme)
    private var colorScheme

    @StateObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @StateObject
    private var paywallStateManager: PaywallStateManager

    private let paywallComponentsData: PaywallComponentsData
    private let uiConfigProvider: UIConfigProvider
    private let offering: Offering
    private let purchaseHandler: PurchaseHandler
    private let onDismiss: () -> Void
    private let fallbackContent: FallbackContent

    public init(
        paywallComponents: Offering.PaywallComponents,
        offering: Offering,
        purchaseHandler: PurchaseHandler,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        onDismiss: @escaping () -> Void,
        fallbackContent: FallbackContent
    ) {
        let uiConfigProvider = UIConfigProvider(uiConfig: paywallComponents.uiConfig)

        self.paywallComponentsData = paywallComponents.data
        self.uiConfigProvider = uiConfigProvider
        self.offering = offering
        self.purchaseHandler = purchaseHandler
        self.onDismiss = onDismiss
        self.fallbackContent = fallbackContent
        self._introOfferEligibilityContext = .init(
            wrappedValue: .init(introEligibilityChecker: introEligibilityChecker)
        )

        // Step 0: Decide which ComponentsConfig to use (base is default)
        let componentsConfig = paywallComponentsData.componentsConfig.base

        // The creation of the paywall view components can be intensive and should only be executed once.
        // The instantiation of the PaywallStateManager needs to stay in the init of the wrappedValue
        // because StateObject init is an autoclosure that will only get executed once.
        self._paywallStateManager = .init(
            wrappedValue: .init(state: Self.createPaywallState(
                componentsConfig: componentsConfig,
                componentsLocalizations: paywallComponents.data.componentsLocalizations,
                defaultLocale: paywallComponents.data.defaultLocale,
                uiConfigProvider: uiConfigProvider,
                offering: offering,
                introEligibilityChecker: introEligibilityChecker,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            ))
        )
    }

    public var body: some View {
        if let errorInfo = self.paywallComponentsData.errorInfo, !errorInfo.isEmpty {
            // Show fallback paywall and debug error message that
            // occurred while decoding the paywall
            self.fallbackViewWithErrorMessage(
                "Error decoding paywall response on: \(errorInfo.keys.joined(separator: ", "))"
            )
        } else {
            switch self.paywallStateManager.state {
            case .success(let paywallState):
                LoadedPaywallsV2View(
                    paywallState: paywallState,
                    uiConfigProvider: self.uiConfigProvider,
                    onDismiss: self.onDismiss
                )
                .environment(\.screenCondition, ScreenCondition.from(self.horizontalSizeClass))
                .environmentObject(self.purchaseHandler)
                .environmentObject(self.introOfferEligibilityContext)
                .disabled(self.purchaseHandler.actionInProgress)
                .onAppear {
                    self.purchaseHandler.trackPaywallImpression(
                        self.createEventData()
                    )
                }
                .onDisappear { self.purchaseHandler.trackPaywallClose() }
                .onChangeOf(self.purchaseHandler.purchased) { purchased in
                    if purchased {
                        self.onDismiss()
                    }
                }
                .task {
                    await self.introOfferEligibilityContext.computeEligibility(for: paywallState.packages)
                }
                // Note: preferences need to be applied after `.toolbar` call
                .preference(key: PurchaseInProgressPreferenceKey.self,
                            value: self.purchaseHandler.packageBeingPurchased)
                .preference(key: PurchasedResultPreferenceKey.self,
                            value: .init(data: self.purchaseHandler.purchaseResult))
                .preference(key: RestoredCustomerInfoPreferenceKey.self,
                            value: self.purchaseHandler.restoredCustomerInfo)
                .preference(key: RestoreInProgressPreferenceKey.self,
                            value: self.purchaseHandler.restoreInProgress)
                .preference(key: PurchaseErrorPreferenceKey.self,
                            value: self.purchaseHandler.purchaseError as NSError?)
                .preference(key: RestoreErrorPreferenceKey.self,
                            value: self.purchaseHandler.restoreError as NSError?)
            case .failure(let error):
                // Show fallback paywall and debug error message that
                // occurred while validating data and view models
                self.fallbackViewWithErrorMessage(
                    "Error validating paywall: \(error.localizedDescription)"
                )
            }
        }
    }

    @ViewBuilder
    func fallbackViewWithErrorMessage(_ errorMessage: String) -> some View {
        let fullMessage = """
        \(errorMessage)
        Validate your paywall is correct in the RevenueCat dashboard,
        update your SDK, or contact RevenueCat support.
        View console logs for full detail.
        The displayed paywall contains default configuration.
        This error will be hidden in production.
        """

        DebugErrorView(
            fullMessage,
            replacement: self.fallbackContent.view()
        )
    }

    private func createEventData() -> PaywallEvent.Data {
        return .init(
            offering: self.offering,
            paywallComponentsData: self.paywallComponentsData,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .current,
            darkMode: self.colorScheme == .dark
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct LoadedPaywallsV2View: View {

    private let paywallState: PaywallState
    private let uiConfigProvider: UIConfigProvider
    private let onDismiss: () -> Void

    @StateObject
    private var selectedPackageContext: PackageContext

    init(paywallState: PaywallState, uiConfigProvider: UIConfigProvider, onDismiss: @escaping () -> Void) {
        self.paywallState = paywallState
        self.uiConfigProvider = uiConfigProvider
        self.onDismiss = onDismiss

        self._selectedPackageContext = .init(
            wrappedValue: .init(
                package: paywallState.viewModelFactory.packageValidator.defaultSelectedPackage,
                variableContext: .init(
                    packages: paywallState.packages,
                    showZeroDecimalPlacePrices: paywallState.showZeroDecimalPlacePrices
                )
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ComponentsView(
                    componentViewModels: [.root(paywallState.rootViewModel)],
                    onDismiss: self.onDismiss
                )
            }
            // Used for header image and sticky footer
            .environment(\.safeAreaInsets, proxy.safeAreaInsets)
            // If the first view in the first stack is an image,
            // we will ignore safe area pass the safe area insets in to environment
            // If the image is in a ZStack, the ZStack will push non-images
            // down with the inset
            .applyIf(paywallState.rootViewModel.firstImageInfo != nil, apply: { view in
                view
                    .edgesIgnoringSafeArea(.top)
            })
            .environmentObject(self.selectedPackageContext)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .backgroundStyle(
                self.paywallState.componentsConfig.background
                    .asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
            )
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
fileprivate extension PaywallsV2View {

    // swiftlint:disable:next function_parameter_count
    static func createPaywallState(
        componentsConfig: PaywallComponentsData.PaywallComponentsConfig,
        componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
        defaultLocale: String,
        uiConfigProvider: UIConfigProvider,
        offering: Offering,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool
    ) -> Result<PaywallState, Error> {
        // Step 1: Get localization
        let localizationProvider = Self.chooseLocalization(
            componentsLocalizations: componentsLocalizations,
            defaultLocale: defaultLocale
        )

        do {
            let factory = ViewModelFactory()
            let root = try factory.toRootViewModel(
                componentsConfig: componentsConfig,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider
            )

            // WIP: Maybe re-enable this later or add some warnings
//            guard packageValidator.isValid else {
//                Logger.error(Strings.paywall_could_not_find_any_packages)
//                throw PackageGroupValidationError.noAvailablePackages("No available packages found")
//            }

            let packages = factory.packageValidator.packages

            return .success(
                .init(
                    componentsConfig: componentsConfig,
                    viewModelFactory: factory,
                    packages: packages,
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

    static func chooseLocalization(
        componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
        defaultLocale: String
    ) -> LocalizationProvider {

        guard !componentsLocalizations.isEmpty else {
            Logger.error(Strings.paywall_contains_no_localization_data)
            return .init(locale: Locale.current, localizedStrings: PaywallComponent.LocalizationDictionary())
        }

        // STEP 1: Get available paywall locales
        let paywallLocales = componentsLocalizations.keys.map { Locale(identifier: $0) }

        // use default locale as a fallback if none of the user's preferred locales are not available in the paywall
        let defaultLocale = Locale(identifier: defaultLocale)

        // STEP 2: choose best locale based on device's list of preferred locales.
        let chosenLocale = Self.preferredLocale(from: paywallLocales) ?? defaultLocale

        // STEP 3: Get localization for one of preferred locales in order
        if let localizedStrings = componentsLocalizations.findLocale(chosenLocale) {
            return .init(locale: chosenLocale, localizedStrings: localizedStrings)
        } else if let localizedStrings = componentsLocalizations.findLocale(defaultLocale) {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale)"))
            return .init(locale: defaultLocale, localizedStrings: localizedStrings)
        } else {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale) or \(defaultLocale)"))
            return .init(locale: defaultLocale, localizedStrings: PaywallComponent.LocalizationDictionary())
        }
    }

    /// Returns the preferred paywall locale from the device's preferred locales.
    ///
    /// The algorithm matches first on language, then on region. If no matching locale is found,
    /// the function returns `nil`.
    ///
    /// - Parameter paywallLocales: An array of `Locale` objects representing the paywall's available locales.
    /// - Returns: A `Locale` available on the paywall chosen based on the device's preferredlocales,
    /// or `nil` if no match is found.
    ///
    /// # Example 1
    ///   device locales: `en_CA, en_US, fr_CA`
    ///   paywall locales: `en_US, fr_FR, en_CA, de_DE`
    ///   returns `en_CA`
    ///
    ///
    /// # Example 2
    ///   device locales: `en_CA, en_US, fr_CA`
    ///   paywall locales: `en_US, fr_FR, de_DE`
    ///   returns `en_US`
    ///
    /// # Example 3
    ///   device locales: `fr_CA, en_CA, en_US`
    ///   paywall locales: `en_US, fr_FR, de_DE, en_CA`
    ///   returns `fr_FR`
    ///
    /// # Example 4
    ///   device locales: `es_ES`
    ///   paywall locales: `en_US, de_DE`
    ///   returns `nil`
    ///
    static func preferredLocale(from paywallLocales: [Locale]) -> Locale? {
        for preferredLocale in Locale.preferredLocales {
            // match language
            if let languageMatch = paywallLocales.first(where: { $0.matchesLanguage(preferredLocale) }) {
                // Look for a match that includes region
                if let exactMatch = paywallLocales.first(where: { $0 == preferredLocale }) {
                    return exactMatch
                }
                // If no region match, return match that matched on region only
                return languageMatch
            }
        }

        return nil
    }
}

#endif
