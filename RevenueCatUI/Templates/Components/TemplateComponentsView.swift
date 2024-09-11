//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs todo

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
        let localizationProvider: LocalizationProvider
        do {
            localizationProvider = try LocalizationProvider.chooseLocalization(for: paywallComponentsData)
        } catch {
            self.componentViewModels = [Self.fallbackPaywallViewModels()]
            return
        }

        self.componentViewModels = paywallComponentsData.componentsConfig.components.map { component in

            // TODO: STEP 2: Validate all packages needed exist (????)

            do {
                // STEP 3: Make the view models & validate all components have required localization
                return try component.toViewModel(
                    offering: offering,
                    localizationProvider: localizationProvider
                )
            } catch {

                // STEP 3.5: Use fallback paywall if viewmodel construction fails
                Logger.error(Strings.paywall_view_model_construction_failed(error))

                return Self.fallbackPaywallViewModels()
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ComponentsView(
                componentViewModels: self.componentViewModels
            )
            Spacer()
        }
        .scrollableIfNecessary()
        .edgesIgnoringSafeArea(.top)
    }

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
