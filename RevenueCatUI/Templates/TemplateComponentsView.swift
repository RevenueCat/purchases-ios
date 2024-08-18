//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import RevenueCat
import SwiftUI
import GameController

enum GameControllerEvent {
    case buttonA(isPressed: Bool)
    case thumbstickPosition(x: Float, y: Float)
    case directionChanged(direction: Direction)

    case rightShoulder(isPressed: Bool)
    case rightTrigger(isPressed: Bool)
    case leftShoulder(isPressed: Bool)
    case leftTrigger(isPressed: Bool)

    enum Direction {
        case none
        case up
        case down
        case left
        case right
    }
}

extension Notification.Name {
    public static let gameControllerEvent = Notification.Name("gameControllerEvent")
}

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
    private var focusManager: FocusManager

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
        let focusableFields = configuration.components?.components.flatMap({ component in
            return component.focusIdentifier ?? []
        }) ?? []

        print("FOCUSABLE fields", focusableFields)

        self.configuration = configuration
        self._focusManager = .init(wrappedValue: .init(focusableFields: focusableFields))
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
                .environmentObject(self.focusManager)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(
            try! PaywallColor(stringRepresentation: self.configuration.components!.backgroundColor.light).underlyingColor
        )
        .onReceive(NotificationCenter.default.publisher(for: .gameControllerEvent)) { notification in
            if let event = notification.userInfo?["event"] as? GameControllerEvent {
                switch event {
                case .buttonA, .rightTrigger, .rightShoulder, .leftTrigger, .leftShoulder:
                    ()
                case .thumbstickPosition(x: let x, y: let y):
                    ()
                case .directionChanged(direction: let direction):
                    switch direction {
                    case .up:
                        self.focusManager.previous()
                    case .down:
                        self.focusManager.next()
                    default:
                        break;
                    }
                }
            }
        }
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
            case .video(let component):
                VideoComponentView(locale: locale, component: component)
            case .carousel(let component):
                CarouselComponentView(locale: locale, component: component)
            case .packages(let component):
//                PackagesComponentView(
                BackbonePackagesComponentView(
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
//                PurchaseButtonComponentView(
                BackbonePurchaseButtonComponentView(
                    locale: locale,
                    component: component,
                    configuration: configuration
                )
            case .spacer(let component):
                SpacerComponentView(
                    locale: locale,
                    component: component
                )
//            case .vstack(let component):
//                 VStack(spacing: component.spacing) {
//                     ComponentsView(components: component.components, locale: locale, configuration: configuration)
//                 }
//                 .background(self.backgroundColor(component.backgroundColor))
//             case .hstack(let component):
//                 HStack(aspacing: component.spacing) {
//                     ComponentsView(components: component.components, locale: locale, configuration: configuration)
//                 }
//                 .background(self.backgroundColor(component.backgroundColor))
//             case .zstack(let component):
//                 ZStack {
//                     ComponentsView(components: component.components, locale: locale, configuration: configuration)
//                 }
//                 .background(self.backgroundColor(component.backgroundColor))
            default:
                EmptyView()
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
private struct VideoComponentView: View {

    let locale: Locale
    let component: PaywallComponent.VideoComponent

    @State private var player: AVPlayer!

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let url = component.url

                player = AVPlayer(url: url)
                player.play()
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CarouselComponentView: View {

    let locale: Locale
    let component: PaywallComponent.CarouselComponent

    @State private var player: AVPlayer!
    @State private var currentIndex = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(component.urls.indices, id: \.self) { index in
                VStack(alignment: .center) {
                    RemoteImage(
                        url: component.urls[index],
                        aspectRatio: 1.5
                    )
                }
                .tag(index)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
                .padding(.bottom, 30)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: .gameControllerEvent)) { notification in
            if let event = notification.userInfo?["event"] as? GameControllerEvent {
                switch event {
                case .buttonA, .rightTrigger, .leftTrigger:
                    ()
                case .rightShoulder:
                    if currentIndex >= (component.urls.count - 1) {
                        currentIndex = 0
                    } else {
                        currentIndex += 1
                    }
                case .leftShoulder:
                    if currentIndex <= 0 {
                        currentIndex = component.urls.count - 1
                    } else {
                        currentIndex -= 1
                    }
                case .thumbstickPosition:
                    ()
                case .directionChanged(direction: let direction):
                    switch direction {
                    case .left, .right:
                        ()
                    default:
                        break;
                    }
                }
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct BackbonePackagesComponentView: View {

    @EnvironmentObject
    private var componentPaywallData: ComponentPaywallData

    let locale: Locale
    let component: PaywallComponent.PackagesComponent
    let configuration: TemplateViewConfiguration
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
        SubscriptionView(component: component)
    }

    struct SubscriptionOption: View {
        let title: String
        let description: String
        let price: String
        let monthlyPrice: String
        let isSelected: Bool
        let isBestValue: Bool

        var body: some View {
            VStack(spacing: 8) {
                Text("BEST VALUE")
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.orange)
                    .cornerRadius(4)
                    .opacity(isBestValue ? 1 : 0)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text(price)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    Text(monthlyPrice)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .background(isSelected ? Color.black : Color.gray.opacity(0.6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                )

//                if isBestValue {
//                    Text("SAVE 20%")
//                        .frame(maxWidth: .infinity)
//                        .font(.caption)
//                        .foregroundColor(.black)
//                        .padding(4)
//                        .background(Color.orange)
//                        .cornerRadius(4)
//                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
        }
    }

    struct SubscriptionView: View {
        @EnvironmentObject
        private var focusManager: FocusManager

        let component: PaywallComponent.PackagesComponent

        @State private var selectedOption: String = "Yearly"

        private var hasFocus: Bool {
            let ids = self.component.focusIdentifiers ?? []
            return ids.contains(self.focusManager.focusedField ?? "")
        }

        var body: some View {
            HStack(spacing: 16) {
                SubscriptionOption(
                    title: "Yearly",
                    description: "30-day free trial",
                    price: "$39.99",
                    monthlyPrice: "$3.33 / Month",
                    isSelected: selectedOption == "Yearly",
                    isBestValue: true
                )
                .onTapGesture {
                    selectedOption = "Yearly"
                }

                SubscriptionOption(
                    title: "Monthly",
                    description: "",
                    price: "$4.99",
                    monthlyPrice: "",
                    isSelected: selectedOption == "Monthly",
                    isBestValue: false
                )
                .onTapGesture {
                    selectedOption = "Monthly"
                }
            }
            .padding()
            .background(Color.black)
            .onChangeOf(self.focusManager.focusedField) { newValue in
                // TODO: Toggle things
            }
            .onReceive(NotificationCenter.default.publisher(for: .gameControllerEvent)) { notification in
                let focusIds = self.component.focusIdentifiers ?? []
                guard focusIds.contains(self.focusManager.focusedField ?? "") else {
                    return
                }

                if let event = notification.userInfo?["event"] as? GameControllerEvent {
                    switch event {
                    case .buttonA, .rightTrigger, .rightShoulder, .leftTrigger, .leftShoulder:
                        ()
                    case .thumbstickPosition:
                        ()
                    case .directionChanged(direction: let direction):
                        switch direction {
                        case .left, .right:
                            if self.selectedOption == "Yearly" {
                                self.selectedOption = "Monthly"
                            } else {
                                self.selectedOption = "Yearly"
                            }
                        default:
                            break;
                        }
                    }
                }
            }
        }
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
private struct BackbonePurchaseButtonComponentView: View {

    let locale: Locale
    let component: PaywallComponent.PurchaseButtonComponent
    let configuration: TemplateViewConfiguration

    @EnvironmentObject
    private var componentPaywallData: ComponentPaywallData

    @EnvironmentObject
    private var focusManager: FocusManager

    @State private var showingAlert = false

    private var hasFocus: Bool {
        let ids = self.component.focusIdentifiers ?? []
        return ids.contains(self.focusManager.focusedField ?? "")
    }

    var body: some View {
        Button(action: {
            purchase()
        }) {
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("Try for free")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("then $39.99/yr. Cancel anytime.")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding()
            .background(hasFocus ? .orange : .white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(NotificationCenter.default.publisher(for: .gameControllerEvent)) { notification in
            let focusIds = self.component.focusIdentifiers ?? []
            guard focusIds.contains(self.focusManager.focusedField ?? "") else {
                return
            }

            if let event = notification.userInfo?["event"] as? GameControllerEvent {
                switch event {
                case .buttonA:
                    purchase()
                case .rightTrigger, .rightShoulder, .leftTrigger, .leftShoulder:
                    ()
                case .thumbstickPosition:
                    ()
                case .directionChanged:
                    ()
                }
            }
        }
        .alert("Demo of purchase button", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func purchase() {
        showingAlert = true
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

class FocusManager: ObservableObject {
    @Published var focusedField: FocusIdentifier?

    let focusableFields: [FocusIdentifier]

    init(focusableFields: [FocusIdentifier]) {
        self._focusedField = .init(initialValue: nil)
        self.focusableFields = focusableFields
    }

    var currentIndex: Int? {
        return focusedField.flatMap { focusableFields.firstIndex(of: $0) }
    }

    func switchIndex(_ value: Int) {
        self.focusedField = self.focusableFields[value]
    }

    func previous() {
        guard let currentIndex else {
            switchIndex(0)
            return
        }

        if currentIndex > 0 {
            switchIndex(currentIndex - 1)
        } else {
            switchIndex(focusableFields.count - 1) // Wrap around to the last item
        }
    }

    func next() {
        guard let currentIndex else {
            switchIndex(0)
            return
        }

        if currentIndex < focusableFields.count - 1 {
            switchIndex(currentIndex + 1)
        } else {
            switchIndex(0) // Wrap around to the first item
        }
    }
}
