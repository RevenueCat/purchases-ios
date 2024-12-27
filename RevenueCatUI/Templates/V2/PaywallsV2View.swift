//
//  File.swift
//
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

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
    let componentViewModel: PaywallComponentViewModel
    let showZeroDecimalPlacePrices: Bool

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallsV2View: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.colorScheme)
    private var colorScheme

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    @StateObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @StateObject
    private var paywallStateManager: PaywallStateManager

    private let paywallComponentsData: PaywallComponentsData
    private let offering: Offering
    private let onDismiss: () -> Void

    public init(
        paywallComponentsData: PaywallComponentsData,
        offering: Offering,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.paywallComponentsData = paywallComponentsData
        self.offering = offering
        self.onDismiss = onDismiss
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
                componentsLocalizations: paywallComponentsData.componentsLocalizations,
                defaultLocale: paywallComponentsData.defaultLocale,
                offering: offering,
                introEligibilityChecker: introEligibilityChecker,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            ))
        )
    }

    public var body: some View {
        switch self.paywallStateManager.state {
        case .success(let paywallState):
            LoadedPaywallsV2View(
                paywallState: paywallState,
                onDismiss: self.onDismiss
            )
            .environment(\.screenCondition, ScreenCondition.from(self.horizontalSizeClass))
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
        case .failure:
            // WIP: Need to use fallback paywall
            Text("Error creating paywall")
        }
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
    private let onDismiss: () -> Void

    @StateObject
    private var selectedPackageContext: PackageContext

    init(paywallState: PaywallState, onDismiss: @escaping () -> Void) {
        self.paywallState = paywallState
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
        VStack(spacing: 0) {
            ComponentsView(
                componentViewModels: [paywallState.componentViewModel],
                onDismiss: self.onDismiss
            )
        }
        .environmentObject(self.selectedPackageContext)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .backgroundStyle(self.paywallState.componentsConfig.background.backgroundStyle)
        .edgesIgnoringSafeArea(.top)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension PaywallsV2View {

    // swiftlint:disable:next function_parameter_count
    static func createPaywallState(
        componentsConfig: PaywallComponentsData.PaywallComponentsConfig,
        componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
        defaultLocale: String,
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
                localizationProvider: localizationProvider
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
                    componentViewModel: .root(root),
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
        if let localizedStrings = componentsLocalizations[chosenLocale.identifier] {
            return .init(locale: chosenLocale, localizedStrings: localizedStrings)
        } else if let localizedStrings = componentsLocalizations[defaultLocale.identifier] {
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

fileprivate extension Locale {

    static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

    func matchesLanguage(_ rhs: Locale) -> Bool {
        self.removingRegion == rhs.removingRegion
    }

    // swiftlint:disable:next identifier_name
    var rc_languageCode: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.languageCode?.identifier
        } else {
            return self.languageCode
        }
        #else
        return self.languageCode
        #endif
    }

    /// - Returns: the same locale as `self` but removing its region.
    private var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

}

#endif
