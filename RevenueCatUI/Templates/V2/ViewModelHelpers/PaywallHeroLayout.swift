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
    let conditionContext: ConditionContext
    let discardRules: Bool

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
        for (index, pair) in zip(components, stack.viewModels).enumerated() {
            var result: PaywallHeroLayout
            if case .stack(let child) = pair.1 {
                guard let leaf = self.firstVisibleLeaf(in: child) else { continue }
                result = leaf
            } else {
                let childProperties = self.properties(for: pair.0)
                guard childProperties.visible != false else { continue }
                result = PaywallHeroLayout(
                    heroIdentifier: childProperties.width?.isFill == true ? pair.1.nativeMediaIdentifier : nil,
                    exemptChildIndicesByStack: [:]
                )
            }
            if result.heroIdentifier != nil, case .zlayer? = properties.dimension {
                result.exemptChildIndicesByStack[ObjectIdentifier(stack)] = index
            }
            return result
        }
        return PaywallHeroLayout.none
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
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
        case .text(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .icon(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .button(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .package(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .timeline(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .tabs(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .carousel(let component):
            return self.visibility(component.visible, overrides: component.overrides, keyPath: \.visible)
        case .purchaseButton, .stickyFooter, .tabControl, .tabControlButton, .tabControlToggle, .countdown,
             .fallbackHeader:
            return .init(visible: true, width: nil, dimension: nil)
        }
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
