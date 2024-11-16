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

enum PackageGroupValidationError: Error {

    case noAvailablePackages(String)

}

struct LocalizationProvider {

    let locale: Locale
    let localizedStrings: PaywallComponent.LocalizationDictionary

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TemplateComponentsView: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @StateObject
    private var selectedPackageContext: PackageContext

    @StateObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    private let paywallComponentsData: PaywallComponentsData
    private let componentViewModel: PaywallComponentViewModel
    private let onDismiss: () -> Void

    private let packages: [Package]

    public init(
        paywallComponentsData: PaywallComponentsData,
        offering: Offering,
        introEligibilityChecker: TrialOrIntroEligibilityChecker,
        showZeroDecimalPlacePrices: Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.paywallComponentsData = paywallComponentsData
        self.onDismiss = onDismiss

        self._introOfferEligibilityContext = .init(
            wrappedValue: .init(introEligibilityChecker: introEligibilityChecker)
        )

        guard (self.paywallComponentsData.errorInfo ?? [:]).isEmpty else {
            self.componentViewModel = Self.fallbackPaywallViewModels()
            self.packages = []
            self._selectedPackageContext = .init(
                wrappedValue: PackageContext(package: nil, variableContext: .init())
            )

            return
        }

        // Step 0: Decide which ComponentsConfig to use (base is default)
        let componentsConfig = paywallComponentsData.componentsConfig.base

        // Step 1: Get localization
        let localizationProvider = Self.chooseLocalization(for: paywallComponentsData)

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

            self.componentViewModel = .root(root)
            self._selectedPackageContext = .init(wrappedValue: PackageContext(
                package: factory.packageValidator.defaultSelectedPackage,
                variableContext: .init(
                    packages: packages,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
                )
            ))
            self.packages = packages
        } catch {
            // STEP 2.5: Use fallback paywall if viewmodel construction fails
            Logger.error(Strings.paywall_view_model_construction_failed(error))

            // WIP: Need to select default package in fallback view model
            self.packages = []
            self.componentViewModel = Self.fallbackPaywallViewModels()
            self._selectedPackageContext = .init(wrappedValue: PackageContext(
                package: nil,
                variableContext: .init()
            ))
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ComponentsView(
                componentViewModels: [self.componentViewModel],
                onDismiss: onDismiss
            )
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.top)
        .environmentObject(self.introOfferEligibilityContext)
        .environmentObject(self.selectedPackageContext)
        .environment(\.screenCondition, ScreenCondition.from(self.horizontalSizeClass))
        .task {
            await self.introOfferEligibilityContext.computeEligibility(for: self.packages)
        }
    }

    static func chooseLocalization(
        for componentsData: PaywallComponentsData
    ) -> LocalizationProvider {

        guard !componentsData.componentsLocalizations.isEmpty else {
            Logger.error(Strings.paywall_contains_no_localization_data)
            return .init(locale: Locale.current, localizedStrings: PaywallComponent.LocalizationDictionary())
        }

        // STEP 1: Get available paywall locales
        let paywallLocales = componentsData.componentsLocalizations.keys.map { Locale(identifier: $0) }

        // use default locale as a fallback if none of the user's preferred locales are not available in the paywall
        let defaultLocale = Locale(identifier: componentsData.defaultLocale)

        // STEP 2: choose best locale based on device's list of preferred locales.
        let chosenLocale = Self.preferredLocale(from: paywallLocales) ?? defaultLocale

        // STEP 3: Get localization for one of preferred locales in order
        if let localizedStrings = componentsData.componentsLocalizations[chosenLocale.identifier] {
            return .init(locale: chosenLocale, localizedStrings: localizedStrings)
        } else if let localizedStrings = componentsData.componentsLocalizations[defaultLocale.identifier] {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale)"))
            return .init(locale: defaultLocale, localizedStrings: localizedStrings)
        } else {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale) or \(defaultLocale)"))
            return .init(locale: defaultLocale, localizedStrings: PaywallComponent.LocalizationDictionary())
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentsView: View {

    let componentViewModels: [PaywallComponentViewModel]
    private let onDismiss: () -> Void

    init(componentViewModels: [PaywallComponentViewModel], onDismiss: @escaping () -> Void) {
        self.componentViewModels = componentViewModels
        self.onDismiss = onDismiss
    }

    var body: some View {
        self.layoutComponents(self.componentViewModels)
    }

    @ViewBuilder
    func layoutComponents(_ componentViewModels: [PaywallComponentViewModel]) -> some View {
        ForEach(Array(componentViewModels.enumerated()), id: \.offset) { _, item in
            switch item {
            case .root(let viewModel):
                RootView(viewModel: viewModel, onDismiss: onDismiss)
            case .text(let viewModel):
                TextComponentView(viewModel: viewModel)
            case .image(let viewModel):
                ImageComponentView(viewModel: viewModel)
            case .spacer(let viewModel):
                SpacerComponentView(viewModel: viewModel)
            case .stack(let viewModel):
                StackComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .linkButton(let viewModel):
                LinkButtonComponentView(viewModel: viewModel)
            case .button(let viewModel):
                ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .package(let viewModel):
                PackageComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .purchaseButton(let viewModel):
                PurchaseButtonComponentView(viewModel: viewModel)
            case .stickyFooter(let viewModel):
                StickyFooterComponentView(viewModel: viewModel)
            }
        }
    }

}

#endif
