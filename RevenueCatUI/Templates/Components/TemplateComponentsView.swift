//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import RevenueCat
import SwiftUI
// swiftlint:disable all

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class ComponentPaywallData: ObservableObject {
//    @Published var selectedPackage: TemplateViewConfiguration.Package
//
//    init(selectedPackage: TemplateViewConfiguration.Package) {
//        self._selectedPackage = .init(initialValue: selectedPackage)
//    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TemplateComponentsView: View {

    let paywallComponentsData: PaywallComponentsData

    @StateObject
    private var componentPaywallData: ComponentPaywallData

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom
    @Environment(\.locale)
    var locale

    #if swift(>=5.9) || (!os(macOS) && !os(watchOS) && !os(tvOS))
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    #endif

    init(paywallComponentsData: PaywallComponentsData) {
        self.paywallComponentsData = paywallComponentsData
        self._componentPaywallData = .init(wrappedValue: .init(/*selectedPackage: configuration.packages.default*/))
    }

    var body: some View {
        VStack(spacing: 0) {
                ComponentsView(
                    locale: self.locale,
                    components: paywallComponentsData.componentsConfig.components,
                    shouldSplitLandscape: true
                )
                .environmentObject(self.componentPaywallData)
        }
        .edgesIgnoringSafeArea(.top)
        .background(

//            try! PaywallColor(stringRepresentation: self.configuration.components!.backgroundColor.light).underlyingColor
        )
    }

}

func getLocalization(_ locale: Locale, _ displayString: DisplayString) -> String {
    if let found = displayString.value[locale.identifier] {
        return found
    }

    return displayString.value.values.first!
}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentsView: View {

    let locale: Locale
    let components: [PaywallComponent]
    let shouldSplitLandscape: Bool

    init(locale: Locale, components: [PaywallComponent], shouldSplitLandscape: Bool = false) {
        self.locale = locale
        self.components = components
        self.shouldSplitLandscape = shouldSplitLandscape
    }

    var body: some View {
            self.layoutComponents(self.components)
//                .scrollableIfNecessaryWhenAvailable()
    }

    @ViewBuilder
    func layoutComponents(_ layoutComponentsArray: [PaywallComponent]) -> some View {
        ForEach(Array(layoutComponentsArray.enumerated()), id: \.offset) { index, item in
            switch (item) {
            case .tiers(let component):
                TiersComponentView(
                    locale: locale,
                    component: component
                )
            case .tierSelector:
                // This gets displayed in TiersComponentView right now
                EmptyView()
            case .tierToggle:
                // This gets displayed in TiersComponentView right now
                EmptyView()
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

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    var defaultHorizontalPaddingLength: CGFloat? {
        return Constants.defaultHorizontalPaddingLength(self.userInterfaceIdiom)
    }

    var defaultVerticalPaddingLength: CGFloat? {
        return Constants.defaultVerticalPaddingLength(self.userInterfaceIdiom)
    }

    #if swift(>=5.9) || (!os(macOS) && !os(watchOS) && !os(tvOS))
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    #endif

    var shouldUseLandscapeLayout: Bool {
        return false
//        #if os(tvOS)
//        // tvOS never reports UserInterfaceSizeClass.compact
//        // but for the purposes of template layouts, we consider landscape
//        // on tvOS as compact to produce horizontal layouts.
//        return true
//        #elseif os(macOS)
//        return false
//        #elseif os(watchOS)
//        return false
//        #else
//        // Ignore size class when displaying footer paywalls.
//        return (self.configuration.mode.isFullScreen &&
//                self.verticalSizeClass == .compact)
//        #endif
    }
    
}

#endif
