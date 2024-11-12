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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StackComponentViewModel {

    private let component: PaywallComponent.StackComponent

    let viewModels: [PaywallComponentViewModel]

    init(
        component: PaywallComponent.StackComponent,
        viewModels: [PaywallComponentViewModel]
    ) {
        self.component = component
        self.viewModels = viewModels
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        apply: @escaping (StackComponentStyle) -> some View
    ) -> some View {
//        let localalizedPartial = self.buildPartial(state: state, condition: condition)
//        let partial = localalizedPartial?.partial
//
//        let style = TextComponentStyle(
//            visible: partial?.visible ?? true,
//            text: localalizedPartial?.text ?? self.text,
//            fontFamily: partial?.fontName ?? self.component.fontName,
//            fontWeight: partial?.fontWeight ?? self.component.fontWeight,
//            color: partial?.color ?? self.component.color,
//            backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
//            size: partial?.size ?? self.component.size,
//            padding: partial?.padding ?? self.component.padding,
//            margin: partial?.margin ?? self.component.margin,
//            fontSize: partial?.fontSize ?? self.component.fontSize,
//            horizontalAlignment: partial?.horizontalAlignment ?? self.component.horizontalAlignment
//        )

        let style = StackComponentStyle(
            visible: true,
            dimension: self.component.dimension,
            size: self.component.size,
            spacing: self.component.spacing,
            backgroundColor: self.component.backgroundColor,
            padding: self.component.padding,
            margin: self.component.margin,
            shape: self.component.shape,
            border: self.component.border,
            shadow: self.component.shadow
        )

        apply(style)
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
        self.backgroundColor = backgroundColor?.toDyanmicColor() ?? Color.clear
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
            color: self.color.toDyanmicColor(),
            width: self.width
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallComponent.Shadow {

    var shadow: ShadowModifier.ShadowInfo? {
        ShadowModifier.ShadowInfo(
            color: self.color.toDyanmicColor(),
            radius: self.radius,
            x: self.x,
            y: self.y
        )
    }

}

#endif
