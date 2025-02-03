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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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
        uiConfigProvider: UIConfigProvider,
        localizationProvider: LocalizationProvider
    ) throws {
        self.component = component
        self.viewModels = viewModels
        self.uiConfigProvider = uiConfigProvider
        self.badgeViewModels = badgeViewModels
        self.shouldApplySafeAreaInset = shouldApplySafeAreaInset
        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides { $0 }
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        apply: @escaping (StackComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: self.presentedOverrides
        )

        let style = StackComponentStyle(
            uiConfigProvider: self.uiConfigProvider,
            badgeViewModels: self.badgeViewModels,
            visible: partial?.visible ?? true,
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
            badge: partial?.badge ?? self.component.badge
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
        let backgroundColor = other?.backgroundColor ?? base?.backgroundColor
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin
        let shape = other?.shape ?? base?.shape
        let border = other?.border ?? base?.border
        let shadow = other?.shadow ?? base?.shadow

        return .init(
            visible: visible,
            dimension: dimension,
            size: size,
            spacing: spacing,
            backgroundColor: backgroundColor,
            padding: padding,
            margin: margin,
            shape: shape,
            border: border,
            shadow: shadow
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
        badge: PaywallComponent.Badge?
    ) {
        self.visible = visible
        self.dimension = dimension
        self.size = size
        self.spacing = spacing
        self.backgroundStyle = background?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle ??
            backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
        self.shape = shape?.shape
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider)
        self.badge = badge?.badge(stackShape: self.shape,
                                  stackBorder: self.border,
                                  badgeViewModels: badgeViewModels,
                                  uiConfigProvider: uiConfigProvider)
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
            return .flex
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
            return .flex
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Shape {

    var shape: ShapeModifier.Shape {
        switch self {
        case .rectangle(let cornerRadiuses):
            let corners = cornerRadiuses.flatMap { cornerRadiuses in
                ShapeModifier.RadiusInfo(
                    topLeft: cornerRadiuses.topLeading ?? 0,
                    topRight: cornerRadiuses.topTrailing ?? 0,
                    bottomLeft: cornerRadiuses.bottomLeading ?? 0,
                    bottomRight: cornerRadiuses.bottomTrailing ?? 0
                )
            }
            return .rectangle(corners)
        case .pill:
            return .pill
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Border {

    func border(uiConfigProvider: UIConfigProvider) -> ShapeModifier.BorderInfo? {
        return ShapeModifier.BorderInfo(
            color: self.color.asDisplayable(uiConfigProvider: uiConfigProvider).toDynamicColor(),
            width: self.width
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Shadow {

    func shadow(uiConfigProvider: UIConfigProvider) -> ShadowModifier.ShadowInfo? {
        return ShadowModifier.ShadowInfo(
            color: self.color.asDisplayable(uiConfigProvider: uiConfigProvider).toDynamicColor(),
            radius: self.radius,
            x: self.x,
            y: self.y
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Badge {

    func badge(stackShape: ShapeModifier.Shape?,
               stackBorder: ShapeModifier.BorderInfo?,
               badgeViewModels: [PaywallComponentViewModel],
               uiConfigProvider: UIConfigProvider) -> BadgeModifier.BadgeInfo? {
        BadgeModifier.BadgeInfo(
            style: self.style,
            alignment: self.alignment,
            stack: self.stack,
            badgeViewModels: badgeViewModels,
            stackShape: stackShape,
            stackBorder: stackBorder,
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif
