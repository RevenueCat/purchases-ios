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

    @Environment(\.locale)
    var locale

    let paywallComponentsData: PaywallComponentsData

    init(paywallComponentsData: PaywallComponentsData) {
        self.paywallComponentsData = paywallComponentsData
    }

    var body: some View {
        VStack(spacing: 0) {
                ComponentsView(
                    locale: self.locale,
                    components: paywallComponentsData.componentsConfig.components
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

    let locale: Locale
    let components: [PaywallComponent]

    // @PublicForExternalTesting
    init(locale: Locale, components: [PaywallComponent]) {
        self.locale = locale
        self.components = components
    }

    // @PublicForExternalTesting
    var body: some View {
        self.layoutComponents(self.components)
    }

    @ViewBuilder
    func layoutComponents(_ layoutComponentsArray: [PaywallComponent]) -> some View {
        ForEach(Array(layoutComponentsArray.enumerated()), id: \.offset) { _, item in
            switch item {
            case .text(let component):
                TextComponentView(locale: locale, component: component)
            case .image(let component):
                ImageComponentView(locale: locale, component: component)
            case .spacer(let component):
                SpacerComponentView(
                    locale: locale,
                    component: component
                )
            case .stack(let component):
                StackComponentView(component: component, locale: locale)
            case .linkButton(let component):
                LinkButtonComponentView(locale: locale, component: component)
            }
        }
    }

}

#endif
