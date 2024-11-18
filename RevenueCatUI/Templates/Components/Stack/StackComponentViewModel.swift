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

#if PAYWALL_COMPONENTS

private typealias PresentedStackPartial = PaywallComponent.PartialStackComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StackComponentViewModel {

    private let component: PaywallComponent.StackComponent
    private let presentedOverrides: PresentedOverrides<PresentedStackPartial>?

    let viewModels: [PaywallComponentViewModel]

    init(
        component: PaywallComponent.StackComponent,
        viewModels: [PaywallComponentViewModel]
    ) throws {
        self.component = component
        self.viewModels = viewModels

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides { $0 }
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        apply: @escaping (StackComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            with: self.presentedOverrides
        )

        let style = StackComponentStyle(
            visible: partial?.visible ?? true,
            dimension: partial?.dimension ?? self.component.dimension,
            size: partial?.size ?? self.component.size,
            spacing: partial?.spacing ?? self.component.spacing,
            backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            shape: partial?.shape ?? self.component.shape,
            border: partial?.border ?? self.component.border,
            shadow: partial?.shadow ?? self.component.shadow
        )

        apply(style)
    }

}

extension PresentedStackPartial: PresentedPartial {

    static func combine(_ base: Self?, with other: Self?) -> Self {

        return .init(
            visible: other?.visible ?? base?.visible,
            dimension: other?.dimension ?? base?.dimension,
            size: other?.size ?? base?.size,
            spacing: other?.spacing ?? base?.spacing,
            backgroundColor: other?.backgroundColor ?? base?.backgroundColor,
            padding: other?.padding ?? base?.padding,
            margin: other?.margin ?? base?.margin,
            shape: other?.shape ?? base?.shape,
            border: other?.border ?? base?.border,
            shadow: other?.shadow ?? base?.shadow
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StackComponentStyle {

    enum StackStrategy {
        case normal, lazy, flex
    }

    let visible: Bool
    let dimension: PaywallComponent.Dimension
    let size: PaywallComponent.Size
    let spacing: CGFloat?
    let backgroundColor: Color
    let padding: EdgeInsets
    let margin: EdgeInsets
    let shape: ShapeModifier.Shape?
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?

    init(
        visible: Bool,
        dimension: PaywallComponent.Dimension,
        size: PaywallComponent.Size,
        spacing: CGFloat?,
        backgroundColor: PaywallComponent.ColorScheme?,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding,
        shape: PaywallComponent.Shape?,
        border: PaywallComponent.Border?,
        shadow: PaywallComponent.Shadow?
    ) {
        self.visible = visible
        self.dimension = dimension
        self.size = size
        self.spacing = spacing
        self.backgroundColor = backgroundColor?.toDynamicColor() ?? Color.clear
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
        self.shape = shape?.shape
        self.border = border?.border
        self.shadow = shadow?.shadow
    }

    var vstackStrategy: StackStrategy {
        // Ensure vertical
        guard case let .vertical(_, distribution) = self.dimension else {
            return .normal
        }

        // Normal strategy for fit
        switch self.size.height {
        case .fit:
            return .normal
        case .fill, .fixed:
            break
        }

        // Normal strategy if start
        guard case .start = distribution else {
            return .flex
        }

        // WIP: Look deeper in tree
//        if self.components.count > 3 {
//            return .lazy
//        } else {
//            return .normal
//        }
        return .lazy
    }

    var hstackStrategy: StackStrategy {
        // Ensure horizontal
        guard case .horizontal = self.dimension else {
            return .normal
        }

        // Not strategy for fit
        switch self.size.width {
        case .fit:
            return .normal
        case .fill, .fixed:
            return .flex
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Shape {

    var shape: ShapeModifier.Shape? {
        switch self {
        case .rectangle(let cornerRadiuses):
            let corners = cornerRadiuses.flatMap { cornerRadiuses in
                ShapeModifier.RadiusInfo(
                    topLeft: cornerRadiuses.topLeading,
                    topRight: cornerRadiuses.topTrailing,
                    bottomLeft: cornerRadiuses.bottomLeading,
                    bottomRight: cornerRadiuses.bottomTrailing
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

    var border: ShapeModifier.BorderInfo? {
        ShapeModifier.BorderInfo(
            color: self.color.toDynamicColor(),
            width: self.width
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Shadow {

    var shadow: ShadowModifier.ShadowInfo? {
        ShadowModifier.ShadowInfo(
            color: self.color.toDynamicColor(),
            radius: self.radius,
            x: self.x,
            y: self.y
        )
    }

}

#endif
