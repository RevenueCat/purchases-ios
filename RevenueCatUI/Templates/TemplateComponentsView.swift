//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import RevenueCat
import SwiftUI

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
                    configuration: self.configuration
                )
                .environmentObject(self.componentPaywallData)
            }
        }
        .scrollableIfNecessaryWhenAvailable()
        .edgesIgnoringSafeArea(.top)
    }

}

private func getLocalization(_ locale: Locale, _ displayString: DisplayString) -> String {
    if let found = displayString.value[locale.identifier] {
        return found
    }

    return displayString.value.values.first!
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ComponentsView: View {

    let locale: Locale
    let components: [PaywallComponent]
    let configuration: TemplateViewConfiguration

    var body: some View {
        ForEach(Array(self.components.enumerated()), id: \.offset) { index, item in
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
            case .text(let component):
                TextComponentView(locale: locale, component: component)
            case .image(let component):
                ImageComponentView(locale: locale, component: component)
            case .packages(let component):
                PackagesComponentView(
                    locale: locale,
                    component: component,
                    configuration: self.configuration
                )
            case .features(let component):
                FeaturesComponentView(
                    locale: locale,
                    component: component,
                    configuration: configuration
                )
            case .purchaseButton(let component):
                PurchaseButtonComponentView(
                    locale: locale,
                    component: component,
                    configuration: configuration
                )
            case .spacer(let component):
                SpacerComponentView(
                    locale: locale,
                    component: component
                )
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct TiersComponentView: View {

    let locale: Locale
    let component: PaywallComponent.TiersComponent
    let configuration: TemplateViewConfiguration

    private var tiers: [PaywallComponent.TiersComponent.TierInfo] {
        return component.tiers
    }

    private var componentBeforeSelector: [PaywallComponent] {
        var selectorFound = false
        let before = tiers[selectedTierIndex].components.filter { component in
            if selectorFound == false {
                if case .tierSelector(_) = component {
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
                }
            }

            return selectorFound
        }

        return selectorFound ? after : tiers[selectedTierIndex].components
    }

    @State private var selectedTierIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            ComponentsView(
                locale: locale,
                components: self.componentBeforeSelector,
                configuration: self.configuration
            )

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

            ComponentsView(
                locale: locale,
                components: self.componentAfterSelector,
                configuration: self.configuration
            )
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
private struct PackagesComponentView: View {

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel

    @EnvironmentObject
    private var componentPaywallData: ComponentPaywallData

    let locale: Locale
    let component: PaywallComponent.PackagesComponent
    let configuration: TemplateViewConfiguration

    @Namespace
    private var namespace

    init(
        locale: Locale,
        component: PaywallComponent.PackagesComponent,
        configuration: TemplateViewConfiguration
    ) {
        self.locale = locale
        self.component = component
        self.configuration = configuration
    }

    var body: some View {
        self.packages
    }

    private var packages: some View {
        VStack(spacing: Constants.defaultPackageVerticalSpacing) {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                let isSelected = self.componentPaywallData.selectedPackage.content === package.content

                Button {
                    self.componentPaywallData.selectedPackage = package
                } label: {
                    self.packageButton(package, selected: isSelected)
                }
                .buttonStyle(PackageButtonStyle())
            }
        }
        .matchedGeometryEffect(id: Geometry.packages, in: self.namespace)
        .defaultHorizontalPadding()
    }

    private static let packageButtonAlignment: Alignment = .leading

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        VStack(alignment: Self.packageButtonAlignment.horizontal, spacing: 5) {
            HStack(alignment: .top) {
                self.packageButtonTitle(package, selected: selected)
                    .defaultHorizontalPadding()
                    .padding(.top, self.defaultVerticalPaddingLength)

                Spacer(minLength: 0)

                self.packageDiscountLabel(package, selected: selected)
            }

            self.offerDetails(package: package, selected: selected)
                .defaultHorizontalPadding()
                .padding(.bottom, self.defaultVerticalPaddingLength)
        }
        .font(self.font(for: .body).weight(.medium))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: Self.packageButtonAlignment)
        .overlay {
            self.roundedRectangle
                .stroke(
                    selected
                    ? self.selectedOutline
                    : self.unselectedOutline,
                    lineWidth: Constants.defaultPackageBorderWidth
                )
        }
    }

    var defaultHorizontalPaddingLength: CGFloat? {
        return Constants.defaultHorizontalPaddingLength(self.userInterfaceIdiom)
    }

    var defaultVerticalPaddingLength: CGFloat? {
        return Constants.defaultVerticalPaddingLength(self.userInterfaceIdiom)
    }

    private static let cornerRadius: CGFloat = Constants.defaultPackageCornerRadius

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
    }

    var selectedOutline = Color.red
    var unselectedOutline = Color.gray

    var selectedDiscountText = Color.green
    var unselectedDiscountText = Color.purple

    @ViewBuilder
    private func packageButtonTitle(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        let image = selected
            ? "checkmark.circle.fill"
            : "circle.fill"
        let color = selected
            ? self.selectedOutline
            : self.unselectedOutline

        HStack {
            Image(systemName: image)
                .foregroundColor(color)

            Text(package.localization.offerName ?? package.content.productName)
        }
    }

    @ViewBuilder
    private func packageDiscountLabel(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        if let discount = package.discountRelativeToMostExpensivePerMonth {
            Text(Localization.localized(discount: discount, locale: self.locale))
                .textCase(.uppercase)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(self.roundedRectangle.foregroundColor(
                    selected
                    ? self.selectedOutline
                    : self.unselectedOutline
                ))
                .foregroundColor(
                    selected
                    ? self.selectedDiscountText
                    : self.unselectedDiscountText
                )
                .font(self.font(for: .caption))
                .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
                .padding(8)
        }
    }

    var text1Color = Color.black

    private func offerDetails(
        package: TemplateViewConfiguration.Package,
        selected: Bool,
        alignment: Alignment = Self.packageButtonAlignment
    ) -> some View {
        // TODO: This needs to be new processed info
//        IntroEligibilityStateView(
//            display: .offerDetails,
//            localization: package.localization,
//            introEligibility: self.introEligibility[package.content],
//            foregroundColor: self.text1Color,
//            alignment: alignment
//        )
        Text("TODO: Fix package description from new custom package schema")
        .fixedSize(horizontal: false, vertical: true)
        .font(self.font(for: .body))
    }

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    func font(for textStyle: Font.TextStyle) -> Font {
        return self.configuration.fonts.font(for: textStyle)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackagesComponentView {

    enum Geometry: Hashable {
        case title
        case features
        case packages
        case subscribeButton
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension FeaturesComponentView {

    enum Geometry: Hashable {
        case title
        case features
        case packages
        case subscribeButton
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PurchaseButtonComponentView {

    enum Geometry: Hashable {
        case title
        case features
        case packages
        case subscribeButton
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct FeaturesComponentView: View {

    let locale: Locale
    let component: PaywallComponent.FeaturesComponent
    let configuration: TemplateViewConfiguration

    var body: some View {
        self.features
            .padding(.top, component.padding.top)
            .padding(.bottom, component.padding.bottom)
            .padding(.leading, component.padding.leading)
            .padding(.trailing, component.padding.trailing)
    }

    @Environment(\.userInterfaceIdiom)
    private var userInterfaceIdiom

    @Namespace
    private var namespace

    private var defaultVerticalPaddingLength: CGFloat? {
        return Constants.defaultVerticalPaddingLength(self.userInterfaceIdiom)
    }

    @ScaledMetric(relativeTo: .body)
    private var iconSize = 25

    private let featureIconColor = Color.red

    @ViewBuilder
    private var features: some View {
        VStack(spacing: self.defaultVerticalPaddingLength) {
            ForEach(Array(self.component.features.enumerated()), id: \.offset) { index, feature in
                HStack {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if let icon = feature.icon {
                                IconView(icon: icon, tint: self.featureIconColor)
                            }
                        }
                        .frame(width: self.iconSize, height: self.iconSize)

                    Text(.init(getLocalization(locale, feature.text)))
                        .font(self.font(for: .body))
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .matchedGeometryEffect(id: Geometry.features, in: self.namespace)
    }

    func font(for textStyle: Font.TextStyle) -> Font {
        return self.configuration.fonts.font(for: textStyle)
    }

}

extension PaywallComponent.FeaturesComponent.Feature {

    var icon: PaywallIcon? {
        return PaywallIcon.init(rawValue: self.iconID)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PurchaseButtonComponentView: View {

    let locale: Locale
    let component: PaywallComponent.PurchaseButtonComponent
    let configuration: TemplateViewConfiguration

    @EnvironmentObject
    private var componentPaywallData: ComponentPaywallData

    @Namespace
    private var namespace

    var body: some View {
        PurchaseButton(
            packages: self.configuration.packages,
            selectedPackage: self.componentPaywallData.selectedPackage,
            colors: PaywallData.Configuration.Colors.init(
                background: "#FFFFFF",
                text1: "#000000",
                text2: "#B2B2B2",
                callToActionBackground: "#5CD27A",
                callToActionForeground: "#FFFFFF",
                accent1: "#BC66FF",
                accent2: "#00FF00"
            ),
            configuration: self.configuration
        )
        .defaultHorizontalPadding()
        .defaultVerticalPadding()
        .matchedGeometryEffect(id: Geometry.subscribeButton, in: self.namespace)
    }

    var ctaBackground: PaywallColor {
        return try! PaywallColor(stringRepresentation: "#FF0000")
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
