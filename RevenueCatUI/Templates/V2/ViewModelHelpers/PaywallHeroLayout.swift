//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

/// One decision supplies both root bleed and overlay clearance along the hero's ancestor chain.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallHeroLayout {

    static let none = Self(heroIdentifier: nil, exemptChildIndicesByStack: [:])

    let heroIdentifier: ObjectIdentifier?
    var exemptChildIndicesByStack: [ObjectIdentifier: Int]

}

/// Projects only layout properties through the same override evaluator used by component rendering.
/// Visible non-media content (including empty stacks) stops the search; hidden branches do not.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallHeroLayoutResolver {

    let state: ComponentViewState
    let condition: ScreenCondition
    let isEligibleForIntroOffer: Bool
    let isEligibleForPromoOffer: Bool
    /// Text rules require a signed offer; other components use optimistic promo eligibility.
    let textPromoOffer: PromotionalOffer?
    let conditionContext: ConditionContext
    let discardRules: Bool
    let eligibilityForPackage: (Package) -> (intro: Bool, promo: Bool)

    func resolve(_ root: StackComponentViewModel) -> PaywallHeroLayout {
        return self.firstVisibleLeaf(in: root) ?? .none
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallHeroLayoutResolver {

    func firstVisibleLeaf(in stack: StackComponentViewModel) -> PaywallHeroLayout? {
        let properties = self.properties(for: .stack(stack.component))
        guard properties.visible != false else { return nil }
        let components = stack.component.components.filter {
            if case .fallbackHeader = $0 { return false }
            return true
        }
        var horizontalHero: PaywallHeroLayout?
        for (index, pair) in zip(components, stack.viewModels).enumerated() {
            var result: PaywallHeroLayout
            if case .stack(let child) = pair.1 {
                guard let leaf = self.firstVisibleLeaf(in: child) else { continue }
                result = leaf
            } else {
                let childProperties = self.properties(for: pair.0)
                guard self.renderedVisibility(for: pair.1) ?? (childProperties.visible != false) else { continue }
                result = PaywallHeroLayout(
                    heroIdentifier: childProperties.width?.isFill == true ? pair.1.nativeMediaIdentifier : nil,
                    exemptChildIndicesByStack: [:]
                )
            }
            // A row can bleed only when the hero is its sole visible child.
            if case .horizontal? = properties.dimension {
                guard horizontalHero == nil, result.heroIdentifier != nil else { return PaywallHeroLayout.none }
                horizontalHero = result
                continue
            }
            if result.heroIdentifier != nil, case .zlayer? = properties.dimension {
                result.exemptChildIndicesByStack[ObjectIdentifier(stack)] = index
            }
            return result
        }
        return horizontalHero ?? PaywallHeroLayout.none
    }

    // swiftlint:disable:next function_body_length
    func properties(for component: PaywallComponent) -> LayoutProperties {
        switch component {
        case .stack(let component):
            return self.resolve(
                base: .init(visible: component.visible, width: nil, dimension: component.dimension),
                overrides: component.overrides
            ) { .init(visible: $0.visible, width: nil, dimension: $0.dimension) }
        case .image(let component):
            return self.resolve(
                base: .init(visible: component.visible, width: component.size.width, dimension: nil),
                overrides: component.overrides
            ) { .init(visible: $0.visible, width: $0.size?.width, dimension: nil) }
        case .video(let component):
            return self.resolve(
                base: .init(visible: component.visible, width: component.size.width, dimension: nil),
                overrides: component.overrides
            ) { .init(visible: $0.visible, width: $0.size?.width, dimension: nil) }
        case .webView(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible,
                                   width: component.size.width)
        case .icon(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .text, .button, .package, .timeline, .tabs, .carousel, .purchaseButton, .stickyFooter,
             .tabControl, .tabControlButton, .tabControlToggle, .countdown, .fallbackHeader:
            return .init(visible: true, width: nil, dimension: nil)
        }
    }

    /// Renderers own their visibility context, including which condition inputs they support.
    func renderedVisibility(for viewModel: PaywallComponentViewModel) -> Bool? {
        let component: any CompositeComponentVisibility
        var state = self.state
        var intro = self.isEligibleForIntroOffer
        var promo = self.isEligibleForPromoOffer
        switch viewModel {
        case .text(let model):
            return model.visible(
                state: self.state, condition: self.condition,
                isEligibleForIntroOffer: self.isEligibleForIntroOffer, promoOffer: self.textPromoOffer,
                conditionContext: self.conditionContext
            )
        case .button(let model): component = model
        case .carousel(let model): component = model
        case .tabs(let model): component = model
        case .timeline(let model): component = model
        case .package(let model):
            guard let package = model.package else { return false }
            component = model
            state = package.identifier == self.conditionContext.selectedPackageId ? .selected : .default
            let eligibility = self.eligibilityForPackage(package)
            intro = eligibility.intro
            promo = eligibility.promo
        default: return nil
        }
        return component.visible(
            state: state, condition: self.condition,
            isEligibleForIntroOffer: intro, isEligibleForPromoOffer: promo,
            selectedPackageId: self.conditionContext.selectedPackageId,
            customVariables: self.conditionContext.customVariables,
            windowSize: self.conditionContext.windowSize
        )
    }

    func visibility<Partial: PaywallPartialComponent>(
        _ visible: Bool?,
        overrides: PaywallComponent.ComponentOverrides<Partial>?,
        keyPath: KeyPath<Partial, Bool?>,
        width: PaywallComponent.SizeConstraint? = nil
    ) -> LayoutProperties {
        return self.resolve(
            base: .init(visible: visible, width: width, dimension: nil),
            overrides: overrides
        ) { .init(visible: $0[keyPath: keyPath], width: nil, dimension: nil) }
    }

    func resolve<Partial: PaywallPartialComponent>(
        base: LayoutProperties,
        overrides: PaywallComponent.ComponentOverrides<Partial>?,
        project: (Partial) -> LayoutProperties
    ) -> LayoutProperties {
        let partial = LayoutProperties.buildPartial(
            state: self.state,
            condition: self.condition,
            isEligibleForIntroOffer: self.isEligibleForIntroOffer,
            isEligibleForPromoOffer: self.isEligibleForPromoOffer,
            conditionContext: self.conditionContext,
            with: overrides?.toPresentedOverrides(discardRules: self.discardRules, convert: project)
        )
        return LayoutProperties.combine(base, with: partial)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private protocol CompositeComponentVisibility {

    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue],
        windowSize: CGSize?
    ) -> Bool

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension ButtonComponentViewModel: CompositeComponentVisibility { }

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PackageComponentViewModel: CompositeComponentVisibility { }

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CarouselComponentViewModel: CompositeComponentVisibility { }

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TabsComponentViewModel: CompositeComponentVisibility { }

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TimelineComponentViewModel: CompositeComponentVisibility { }

private struct LayoutProperties: PresentedPartial {

    let visible: Bool?
    let width: PaywallComponent.SizeConstraint?
    let dimension: PaywallComponent.Dimension?

    static func combine(_ base: Self?, with other: Self?) -> Self {
        return .init(visible: other?.visible ?? base?.visible,
                     width: other?.width ?? base?.width,
                     dimension: other?.dimension ?? base?.dimension)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallHeroLayoutKey: EnvironmentKey {

    static let defaultValue: PaywallHeroLayout? = nil

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var paywallHeroLayout: PaywallHeroLayout? {
        get { self[PaywallHeroLayoutKey.self] }
        set { self[PaywallHeroLayoutKey.self] = newValue }
    }

}

#endif
