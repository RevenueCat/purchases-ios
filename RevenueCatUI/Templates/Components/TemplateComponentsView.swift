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
struct TemplateComponentsView: View {

    let paywallComponentsData: PaywallComponentsData
    let componentViewModels: [PaywallComponentViewModel]

    @MainActor
    init(paywallComponentsData: PaywallComponentsData, locale: Locale, offering: Offering) {
        self.paywallComponentsData = paywallComponentsData

        let components = paywallComponentsData.componentsConfig.components
        self.componentViewModels = components.map { component in

            // STEP 1 - Get list of preferred locales (and default)

            // STEP 2 - Get localization for one of preferred locales in order
            // TOOD: This logic is so wrong
            let localizations = paywallComponentsData.componentsLocalizations
            let localization = localizations[locale.identifier] ?? localizations.values.first ?? [String:String]()

            // Step 3 - Validate all variables are supported in localization

            // Step 3.5 - Validate all packages needed exist (????)

            // Step 4 - Make the view models
            return component.toViewModel(offering: offering, locale: locale, localization: localization)
        }
    }

    var body: some View {
        // Step 5 - Show fallback paywall and/or pop error messages if any validation errors occured
        VStack(spacing: 0) {
                ComponentsView(
                    componentViewModels: self.componentViewModels
                )
        }
        .edgesIgnoringSafeArea(.top)
    }

}

func getLocalization(_ locale: Locale, _ displayString: DisplayString) -> String {
    if let found = displayString.value[locale.identifier] {
        return found
    }

    return displayString.value.values.first!
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
struct ComponentsView: View {

    let componentViewModels: [PaywallComponentViewModel]

    // @PublicForExternalTesting
    init(componentViewModels: [PaywallComponentViewModel]) {
        self.componentViewModels = componentViewModels
    }

    // @PublicForExternalTesting
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
                StackComponentView(viewModel: viewModel)
            case .linkButton(let viewModel):
                LinkButtonComponentView(viewModel: viewModel)
            }
        }
    }

}

#endif
