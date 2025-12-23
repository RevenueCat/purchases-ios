//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SizeModifier.swift
//
//  Created by Josh Holtz on 11/11/24.

import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

struct SizeModifier: ViewModifier {

    var size: PaywallComponent.Size
    var hortizontalAlignment: Alignment
    var verticalAlignment: Alignment

    func body(content: Content) -> some View {
        content
            .applyWidth(size.width, alignment: hortizontalAlignment)
            .applyHeight(size.height, alignment: verticalAlignment)
    }

}

fileprivate extension View {

    @ViewBuilder
    func applyWidth(_ sizeConstraint: PaywallComponent.SizeConstraint, alignment: Alignment) -> some View {
        switch sizeConstraint {
        case .fit:
            self
        case .fill:
            self
                .frame(maxWidth: .infinity, alignment: alignment)
        case .fixed(let value):
            self
                .frame(width: CGFloat(value), alignment: alignment)
        case .relative:
            // WIP: Maybe handle
            self
        }
    }

    @ViewBuilder
    func applyHeight(_ sizeConstraint: PaywallComponent.SizeConstraint, alignment: Alignment) -> some View {
        switch sizeConstraint {
        case .fit:
            self
        case .fill:
            self
                .frame(maxHeight: .infinity, alignment: alignment)
        case .fixed(let value):
            self
                .frame(height: CGFloat(value), alignment: alignment)
        case .relative:
            // WIP: Maybe handle
            self
        }
    }

}

extension View {

    func size(_ size: PaywallComponent.Size,
              horizontalAlignment: Alignment = .center,
              verticalAlignment: Alignment = .center) -> some View {
        self.modifier(SizeModifier(size: size,
                                   hortizontalAlignment: horizontalAlignment,
                                   verticalAlignment: verticalAlignment))
    }

}

#endif
