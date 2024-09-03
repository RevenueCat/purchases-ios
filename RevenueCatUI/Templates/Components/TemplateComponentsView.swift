//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct TemplateComponentsView: View {

    let paywallComponentsData: PaywallComponentsData
    let componentViewModels: [PaywallComponentViewModel]

    public init(paywallComponentsData: PaywallComponentsData, offering: Offering) {
        self.paywallComponentsData = paywallComponentsData

        // Step 1: Get localization
        let localization = Self.chooseLocalization(for: paywallComponentsData)

        self.componentViewModels = paywallComponentsData.componentsConfig.components.map { component in

            //TODO: STEP 2: Validate all packages needed exist (????)

            do {
                // STEP 3: Make the view models & validate all components have required localization
                return try component.toViewModel(offering: offering, locale: localization.locale, localization: localization.dict)
            } catch {

                // STEP 3.5: Use fallback paywall if viewmodel construction fails
                Logger.error("View model construction failed: \(error)")
                Logger.debug("Will use fallback paywall.")

                return Self.fallbackPaywallViewModels()
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
                ComponentsView(
                    componentViewModels: self.componentViewModels
                )
        }
        .edgesIgnoringSafeArea(.top)
    }

    static func chooseLocalization(for componentsData: PaywallComponentsData) -> (locale: Locale, dict: [String: String]) {
        guard !componentsData.componentsLocalizations.isEmpty else {
            Logger.error("Paywall contains no localization data.")
            return (Locale.current, [String: String]())
        }

        // STEP 1: Get available paywall locales
        let paywallLocales = componentsData.componentsLocalizations.keys.map { Locale(identifier: $0) }

        let fallbackLocale = Locale(identifier: componentsData.defaultLocale)

        // STEP 2: choose best locale based on device's list of preferred locales.
        let chosenLocale = Self.preferredLocale(from: paywallLocales) ?? fallbackLocale

        // STEP 3: Get localization for one of preferred locales in order
        if let localizationDict = componentsData.componentsLocalizations[chosenLocale.identifier] {
            return (chosenLocale, localizationDict)
        } else if let localizationDict = componentsData.componentsLocalizations[fallbackLocale.identifier] {
            Logger.error("Could not find localization data for \(chosenLocale).")
            return (fallbackLocale, localizationDict)
        } else {
            Logger.error("Could not find localization data for \(chosenLocale) or \(fallbackLocale).")
            return (fallbackLocale, [String: String]())
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ComponentsView: View {

    let componentViewModels: [PaywallComponentViewModel]

    public init(componentViewModels: [PaywallComponentViewModel]) {
        self.componentViewModels = componentViewModels
    }

    public var body: some View {
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
                StackComponentView(viewModel: viewModel)
            case .linkButton(let viewModel):
                LinkButtonComponentView(viewModel: viewModel)
            }
        }
    }

}

#endif
