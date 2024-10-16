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

class PaywallState: ObservableObject {

    @Published var selectedPackage: Package?

    func select(package: Package) {
        self.selectedPackage = package
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct TemplateComponentsView: View {

    let paywallComponentsData: PaywallComponentsData
    let componentViewModels: [PaywallComponentViewModel]
    private let onDismiss: () -> Void

    @StateObject
    var paywwallState = PaywallState()

    public init(paywallComponentsData: PaywallComponentsData, offering: Offering, onDismiss: @escaping () -> Void) {
        self.paywallComponentsData = paywallComponentsData
        self.onDismiss = onDismiss

        // Step 1: Get localization
        let localization = Self.chooseLocalization(for: paywallComponentsData)

        self.componentViewModels = paywallComponentsData.componentsConfig.components.map { component in

            do {
                // STEP 2: Make the view models & validate all components have required localization and packages
                return try component.toViewModel(offering: offering,
                                                 localizedStrings: localization.localizedStrings)
            } catch {

                // STEP 2.5: Use fallback paywall if viewmodel construction fails
                Logger.error(Strings.paywall_view_model_construction_failed(error))

                return Self.fallbackPaywallViewModels()
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ComponentsView(
                componentViewModels: self.componentViewModels,
                onDismiss: onDismiss
            )
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.top)
        .environmentObject(self.paywwallState)
    }

    static func chooseLocalization(
        for componentsData: PaywallComponentsData
    ) -> (locale: Locale, localizedStrings: PaywallComponent.LocalizationDictionary) {

        guard !componentsData.componentsLocalizations.isEmpty else {
            Logger.error(Strings.paywall_contains_no_localization_data)
            return (Locale.current, PaywallComponent.LocalizationDictionary())
        }

        // STEP 1: Get available paywall locales
        let paywallLocales = componentsData.componentsLocalizations.keys.map { Locale(identifier: $0) }

        // use default locale as a fallback if none of the user's preferred locales are not available in the paywall
        let defaultLocale = Locale(identifier: componentsData.defaultLocale)

        // STEP 2: choose best locale based on device's list of preferred locales.
        let chosenLocale = Self.preferredLocale(from: paywallLocales) ?? defaultLocale

        // STEP 3: Get localization for one of preferred locales in order
        if let localizedStrings = componentsData.componentsLocalizations[chosenLocale.identifier] {
            return (chosenLocale, localizedStrings)
        } else if let localizedStrings = componentsData.componentsLocalizations[defaultLocale.identifier] {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale)"))
            return (defaultLocale, localizedStrings)
        } else {
            Logger.error(Strings.paywall_could_not_find_localization("\(chosenLocale) or \(defaultLocale)"))
            return (defaultLocale, PaywallComponent.LocalizationDictionary())
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
            case .packageGroup(let viewModel):
                PackageGroupComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .package(let viewModel):
                PackageComponentView(viewModel: viewModel, onDismiss: onDismiss)
            case .purchaseButton(let viewModel):
                PurchaseButtonComponentView(viewModel: viewModel)
            }
        }
    }

}

#endif
