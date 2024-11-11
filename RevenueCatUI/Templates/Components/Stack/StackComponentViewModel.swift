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

    var shouldUseVStack: Bool {
        switch self.dimension {
        case .vertical:
            if viewModels.count < 3 {
                return true
            }
            return false
        case .horizontal, .zlayer:
            return false
        }
    }

    var shouldUseFlex: Bool {
        // TODO: Maybe fix this
        switch self.component.size.width {
        case .fit:
            return false
        case .fill:
            return true
        case .fixed:
            return true
        }
    }

    var dimension: PaywallComponent.Dimension {
        component.dimension
    }

    var components: [PaywallComponent] {
        component.components
    }

    var spacing: CGFloat? {
        component.spacing
    }

    var backgroundColor: Color {
        component.backgroundColor?.toDyanmicColor() ?? Color.clear
    }

    var padding: EdgeInsets {
        component.padding.edgeInsets
    }

    var margin: EdgeInsets {
        component.margin.edgeInsets
    }

    var width: PaywallComponent.SizeConstraint {
        component.size.width
    }

    var height: PaywallComponent.SizeConstraint {
        component.size.height
    }

    var cornerRadiuses: CornerBorderModifier.RaidusInfo? {
        component.cornerRadiuses.flatMap { cornerRadiuses in
            CornerBorderModifier.RaidusInfo(
                topLeft: cornerRadiuses.topLeading,
                topRight: cornerRadiuses.topTrailing,
                bottomLeft: cornerRadiuses.bottomLeading,
                bottomRight: cornerRadiuses.bottomLeading
            )
        }
    }

    var border: CornerBorderModifier.BorderInfo? {
        component.border.flatMap { border in
            CornerBorderModifier.BorderInfo(
                color: border.color.toDyanmicColor(),
                width: border.width
            )
        }
    }

    var shadow: ShadowModifier.ShadowInfo? {
        component.shadow.flatMap { shadow in
            ShadowModifier.ShadowInfo(
                color: shadow.color.toDyanmicColor(),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
        }
    }

}

#endif
