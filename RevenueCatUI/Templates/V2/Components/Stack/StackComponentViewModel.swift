//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentView.swift
//
//  Created by James Borthwick on 2024-08-20.

import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

typealias PresentedStackPartial = PaywallComponent.PartialStackComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StackComponentViewModel {

    let component: PaywallComponent.StackComponent
    let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedStackPartial>?

    let viewModels: [PaywallComponentViewModel]
    let badgeViewModels: [PaywallComponentViewModel]
    let shouldApplySafeAreaInset: Bool

    init(
        component: PaywallComponent.StackComponent,
        viewModels: [PaywallComponentViewModel],
        badgeViewModels: [PaywallComponentViewModel],
        shouldApplySafeAreaInset: Bool = false,
        uiConfigProvider: UIConfigProvider
    ) {
        self.component = component
        self.viewModels = viewModels
        self.uiConfigProvider = uiConfigProvider
        self.badgeViewModels = badgeViewModels
        self.shouldApplySafeAreaInset = shouldApplySafeAreaInset
        self.presentedOverrides = self.component.overrides?.toPresentedOverrides { $0 }
    }

    func copy(withViewModels newViewModels: [PaywallComponentViewModel]) -> StackComponentViewModel {
        return StackComponentViewModel(
            component: self.component,
            viewModels: newViewModels,
            badgeViewModels: self.badgeViewModels,
            shouldApplySafeAreaInset: self.shouldApplySafeAreaInset,
            uiConfigProvider: self.uiConfigProvider
        )
    }

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        colorScheme: ColorScheme,
        @ViewBuilder apply: @escaping (StackComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = StackComponentStyle(
            uiConfigProvider: self.uiConfigProvider,
            badgeViewModels: self.badgeViewModels,
            visible: partial?.visible ?? self.component.visible ?? true,
            dimension: partial?.dimension ?? self.component.dimension,
            size: partial?.size ?? self.component.size,
            spacing: partial?.spacing ?? self.component.spacing,
            backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
            background: partial?.background ?? self.component.background,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            shape: partial?.shape ?? self.component.shape,
            border: partial?.border ?? self.component.border,
            shadow: partial?.shadow ?? self.component.shadow,
            badge: partial?.badge ?? self.component.badge,
            overflow: partial?.overflow ?? self.component.overflow,
            colorScheme: colorScheme
        )

        apply(style)
    }

}

extension PresentedStackPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialStackComponent?,
        with other: PaywallComponent.PartialStackComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let dimension = other?.dimension ?? base?.dimension
        let size = other?.size ?? base?.size
        let spacing = other?.spacing ?? base?.spacing
        let background = other?.background ?? base?.background
        let backgroundColor = other?.backgroundColor ?? base?.backgroundColor
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin
        let shape = other?.shape ?? base?.shape
        let border = other?.border ?? base?.border
        let shadow = other?.shadow ?? base?.shadow
        let badge = other?.badge ?? base?.badge

        return .init(
            visible: visible,
            dimension: dimension,
            size: size,
            spacing: spacing,
            backgroundColor: backgroundColor,
            background: background,
            padding: padding,
            margin: margin,
            shape: shape,
            border: border,
            shadow: shadow,
            badge: badge
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StackComponentStyle {

    enum StackStrategy {
        case normal, flex
    }

    let visible: Bool
    let dimension: PaywallComponent.Dimension
    let size: PaywallComponent.Size
    let spacing: CGFloat?
    let backgroundStyle: BackgroundStyle?
    let padding: EdgeInsets
    let margin: EdgeInsets
    let shape: ShapeModifier.Shape?
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?
    let badge: BadgeModifier.BadgeInfo?
    let scrollable: Bool?

    init(
        uiConfigProvider: UIConfigProvider,
        badgeViewModels: [PaywallComponentViewModel],
        visible: Bool,
        dimension: PaywallComponent.Dimension,
        size: PaywallComponent.Size,
        spacing: CGFloat?,
        backgroundColor: PaywallComponent.ColorScheme?,
        background: PaywallComponent.Background?,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding,
        shape: PaywallComponent.Shape?,
        border: PaywallComponent.Border?,
        shadow: PaywallComponent.Shadow?,
        badge: PaywallComponent.Badge?,
        overflow: PaywallComponent.StackComponent.Overflow?,
        colorScheme: ColorScheme
    ) {
        self.visible = visible
        self.dimension = dimension
        self.size = size
        self.spacing = spacing
        self.backgroundStyle = background?.asDisplayable(uiConfigProvider: uiConfigProvider) ??
            backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
        self.shape = shape?.shape
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)
        self.badge = badge?.badge(stackShape: self.shape,
                                  stackBorder: badge?.stack.border?.border(uiConfigProvider: uiConfigProvider),
                                  badgeViewModels: badgeViewModels,
                                  uiConfigProvider: uiConfigProvider)

        self.scrollable = overflow.flatMap({ overflow in
            switch overflow {
            case .default:
                return false
            case .scroll:
                return true
            }
        })
    }

    var vstackStrategy: StackStrategy {
        // Ensure vertical
        guard case let .vertical(_, distribution) = self.dimension else {
            return .normal
        }

        switch distribution {
        case .start, .center, .end:
            return .normal
        case .spaceBetween, .spaceAround, .spaceEvenly:
            // We dont want to use a flex stack if its axis is set to fit.
            // Otherwise we would be adding Spacer()'s which would make the stack act as fill.
            if self.size.height == .fit {
                return .normal
            } else {
                return .flex
            }
        }
    }

    var hstackStrategy: StackStrategy {
        // Ensure horizontal
        guard case let .horizontal(_, distribution) = self.dimension else {
            return .normal
        }

        switch distribution {
        case .start, .center, .end:
            return .normal
        case .spaceBetween, .spaceAround, .spaceEvenly:
            // We dont want to use a flex stack if its axis is set to fit.
            // Otherwise we would be adding Spacer()'s which would make the stack act as fill.
            if self.size.width == .fit {
                return .normal
            } else {
                return .flex
            }
        }
    }

}

#endif
