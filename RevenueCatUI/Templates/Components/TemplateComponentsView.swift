//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import RevenueCat
import SwiftUI


extension Locale {

    fileprivate static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

    fileprivate static var deviceLocales: [Self] {
        Self.preferredLocales.flatMap { [$0, $0.removingRegion].compactMap { $0 } }
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
    var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

    static func preferredLocale(from paywallLocales: [Locale]) -> Locale? {
        for deviceLocale in deviceLocales {
            if let match = paywallLocales.first(where: { $0 == deviceLocale || $0.removingRegion == deviceLocale }) {
                return match
            }
        }
        return nil
    }

}


#if PAYWALL_COMPONENTS
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct TemplateComponentsView: View {

    let paywallComponentsData: PaywallComponentsData
    let componentViewModels: [PaywallComponentViewModel]

    public init(paywallComponentsData: PaywallComponentsData, offering: Offering) {
        self.paywallComponentsData = paywallComponentsData

        let components = paywallComponentsData.componentsConfig.components

        // STEP 1 - Get available paywall locales
        let paywallLocales = paywallComponentsData.componentsLocalizations.keys.map { Locale(identifier: $0) }

        // STEP 2 - choose best locale based on device's list of preferred locales.
        let chosenLocale = Locale.preferredLocale(from: paywallLocales) ?? paywallLocales.first! //TODO: should be default

        // STEP 2 - Get localization for one of preferred locales in order
        // TODO: use default locale
        let paywallLocalizations = paywallComponentsData.componentsLocalizations
        let localizationDict = paywallLocalizations[chosenLocale.identifier] ??
                                 paywallLocalizations[paywallLocales.first!.identifier, default: [String: String]()]

        self.componentViewModels = components.map { component in

            // Step 3 - Validate all variables are supported in localization - done in ViewModel creation

            // Step 3.5 - Validate all packages needed exist (????)

            // Step 4 - Make the view models
            do {
                return try component.toViewModel(offering: offering, locale: chosenLocale, localization: localizationDict)
            } catch {
                let errorDict: [String: String] = ["errorID": "Error creating paywall"]
                let textComponent = PaywallComponent.TextComponent(
                    text: DisplayString(value: errorDict),
                    textLid: "errorID",
                    color: PaywallComponent.ColorInfo(light:"#000000")
                )
                return try! PaywallComponentViewModel.text(TextComponentViewModel(locale: .current, localization: errorDict, component: textComponent))
            }
        }
    }

    public var body: some View {
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
