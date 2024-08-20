//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import RevenueCat
import SwiftUI
// swiftlint:disable all

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class ComponentPaywallData: ObservableObject {
    @Published var selectedPackage: TemplateViewConfiguration.Package

    init(selectedPackage: TemplateViewConfiguration.Package) {
        self._selectedPackage = .init(initialValue: selectedPackage)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TemplateComponentsView: TemplateViewType {


    @StateObject
    private var componentPaywallData: ComponentPaywallData

    let configuration: TemplateViewConfiguration

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom
    @Environment(\.locale)
    var locale

    #if swift(>=5.9) || (!os(macOS) && !os(watchOS) && !os(tvOS))
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    #endif

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
        self._componentPaywallData = .init(wrappedValue: .init(selectedPackage: configuration.packages.default))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let data = self.configuration.components {
                ComponentsView(
                    locale: self.locale,
                    components: data.components,
                    configuration: self.configuration,
                    shouldSplitLandscape: true
                )
                .environmentObject(self.componentPaywallData)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(
            try! PaywallColor(stringRepresentation: self.configuration.components!.backgroundColor.light).underlyingColor
        )
    }

}

private func getLocalization(_ locale: Locale, _ displayString: DisplayString) -> String {
    if let found = displayString.value[locale.identifier] {
        return found
    }

    return displayString.value.values.first!
}

import AVKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ComponentsView: View {

    let locale: Locale
    let components: [PaywallComponent]
    let configuration: TemplateViewConfiguration
    let shouldSplitLandscape: Bool

    init(locale: Locale, components: [PaywallComponent], configuration: TemplateViewConfiguration, shouldSplitLandscape: Bool = false) {
        self.locale = locale
        self.components = components
        self.configuration = configuration
        self.shouldSplitLandscape = shouldSplitLandscape
    }

    var landscapeLeftComponents: [PaywallComponent] {
        return self.components.filter { component in
            guard let displayPreferences = component.displayPreferences else {
                return true
            }
            return displayPreferences.contains(.landscapeLeft)
        }
    }

    var landscapeRightComponents: [PaywallComponent] {
        return self.components.filter { component in
            guard let displayPreferences = component.displayPreferences else {
                return true
            }
            return displayPreferences.contains(.landscapeRight)
        }
    }

    var portraitComponents: [PaywallComponent] {
        return self.components.filter { component in
            guard let displayPreferences = component.displayPreferences else {
                return true
            }
            return displayPreferences.contains(.portrait)
        }
    }

    var body: some View {
        if self.shouldUseLandscapeLayout {
            HStack {
                VStack(spacing: 0) {
                    self.layoutComponents(self.landscapeLeftComponents)
                }
//                .scrollableIfNecessaryWhenAvailable()

                VStack(spacing: 0) {
                    self.layoutComponents(self.landscapeRightComponents)
                }
//                .scrollableIfNecessaryWhenAvailable()
            }

        } else {
            self.layoutComponents(self.portraitComponents)
//                .scrollableIfNecessaryWhenAvailable()
        }
    }

    @ViewBuilder
    func layoutComponents(_ layoutComponents: [PaywallComponent]) -> some View {
        ForEach(Array(layoutComponents.enumerated()), id: \.offset) { index, item in
            switch (item) {
            case .tiers(let component):
                TiersComponentView(
                    locale: locale,
                    component: component,
                    configuration: configuration
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
        #if os(tvOS)
        // tvOS never reports UserInterfaceSizeClass.compact
        // but for the purposes of template layouts, we consider landscape
        // on tvOS as compact to produce horizontal layouts.
        return true
        #elseif os(macOS)
        return false
        #elseif os(watchOS)
        return false
        #else
        // Ignore size class when displaying footer paywalls.
        return (self.configuration.mode.isFullScreen &&
                self.verticalSizeClass == .compact)
        #endif
    }
    
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct TiersComponentView: View {

    let locale: Locale
    let component: PaywallComponent.TiersComponent
    let configuration: TemplateViewConfiguration

    @State private var selectedTierIndex = 0

    private var tiers: [PaywallComponent.TiersComponent.TierInfo] {
        return component.tiers
    }

    private var componentBeforeSelector: [PaywallComponent] {
        var selectorFound = false
        let before = tiers[selectedTierIndex].components.filter { component in
            if selectorFound == false {
                if case .tierSelector(_) = component {
                    selectorFound = true
                } else if case .tierToggle(_) = component {
                    selectorFound = true
                }
            }

            return !selectorFound
        }

        return selectorFound ? before : []
    }

    private var componentAfterSelector: [PaywallComponent] {
        var selectorFound = false
        let after = tiers[selectedTierIndex].components.filter { component in
            if selectorFound == false {
                if case .tierSelector(_) = component {
                    selectorFound = true
                } else if case .tierToggle(_) = component {
                    selectorFound = true
                }
            }

            return selectorFound
        }

        return selectorFound ? after : tiers[selectedTierIndex].components
    }

    var tierSelector: PaywallComponent.TierSelectorComponent? {
        return tiers[selectedTierIndex].components.compactMap { component in
            if case .tierSelector(let tierSelectorView) = component {
                return tierSelectorView
            }

            return nil
        }.first
    }

    var tierToggle: PaywallComponent.TierToggleComponent? {
        return tiers[selectedTierIndex].components.compactMap { component in
            if case .tierToggle(let tierToggle) = component {
                return tierToggle
            }

            return nil
        }.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ComponentsView(
                locale: locale,
                components: self.componentBeforeSelector,
                configuration: self.configuration
            )

            if let tierSelector {
                TierSelectorComponentView(
                    locale: locale,
                    component: tierSelector,
                    tiers: tiers,
                    selectedTierIndex: $selectedTierIndex
                )
            } else if let tierToggle {
                TierToggleComponentView(
                    locale: locale,
                    component: tierToggle,
                    tiers: tiers,
                    selectedTierIndex: $selectedTierIndex
                )
            } else {
                TierSelectorComponentView(
                    locale: locale,
                    component: .init(displayPreferences: self.component.displayPreferences),
                    tiers: tiers,
                    selectedTierIndex: $selectedTierIndex
                )
            }

            ComponentsView(
                locale: locale,
                components: self.componentAfterSelector,
                configuration: self.configuration
            )
        }
    }

    struct TierSelectorComponentView: View {

        let locale: Locale
        let component: PaywallComponent.TierSelectorComponent
        let tiers: [PaywallComponent.TiersComponent.TierInfo]
        @Binding var selectedTierIndex: Int

        var body: some View {
            Picker("Options", selection: $selectedTierIndex) {
                ForEach(Array(self.tiers.map { $0.id }.enumerated()), id: \.offset) { index, item in
                    Text(
                        getLocalization(locale, self.tiers[index].displayName)
                    ).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .defaultVerticalPadding()
            .defaultHorizontalPadding()
        }
    }

    struct TierToggleComponentView: View {
        internal init(locale: Locale, component: PaywallComponent.TierToggleComponent, tiers: [PaywallComponent.TiersComponent.TierInfo], selectedTierIndex: Binding<Int>) {
            self.locale = locale
            self.component = component
            self.tiers = tiers
            self._selectedTierIndex = selectedTierIndex
            self.isOn = component.defaultValue
        }
        

        private let locale: Locale
        private let component: PaywallComponent.TierToggleComponent
        private let tiers: [PaywallComponent.TiersComponent.TierInfo]
        @Binding private var selectedTierIndex: Int

        @State private var isOn: Bool

        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Toggle(isOn: $isOn, label: {
                        Text(getLocalization(locale, component.text))
                    })
                    .onChangeOf(self.isOn, perform: { newValue in
                        self.selectedTierIndex = isOn ? 1 : 0
                    })
                    .defaultVerticalPadding()
                    .defaultHorizontalPadding()
                    Spacer()
                }
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct TextComponentView: View {

    let locale: Locale
    let component: PaywallComponent.TextComponent

    var body: some View {
        Text(getLocalization(locale, component.text))
            .multilineTextAlignment(component.horizontalAlignment.alignment)
            .frame(maxWidth: .infinity)
            .font(component.textStyle.font)
            .foregroundStyle(
                try! PaywallColor(stringRepresentation: component.color.light).underlyingColor
            )
            .padding(.top, component.padding.top)
            .padding(.bottom, component.padding.bottom)
            .padding(.leading, component.padding.leading)
            .padding(.trailing, component.padding.trailing)
            .background(self.backgroundColor)
    }

    var backgroundColor: Color? {
        if let thing = component.backgroundColor?.light {
            return try! PaywallColor(stringRepresentation: thing).underlyingColor
        }
        return nil
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ImageComponentView: View {

    let locale: Locale
    let component: PaywallComponent.ImageComponent

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    private var headerAspectRatio: CGFloat {
        switch self.userInterfaceIdiom {
        case .pad: return 3
        default: return 2
        }
    }

    var body: some View {
        RemoteImage(url: component.url,
                    aspectRatio: self.headerAspectRatio,
                    maxWidth: .infinity)
        .clipped()
    }

}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct SpacerComponentView: View {

    let locale: Locale
    let component: PaywallComponent.SpacerComponent

    var body: some View {
        Spacer()
    }
}
