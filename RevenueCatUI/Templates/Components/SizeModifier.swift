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

#if PAYWALL_COMPONENTS

struct SizeModifier: ViewModifier {

    var size: PaywallComponent.Size

    func body(content: Content) -> some View {
        content
            .applyWidth(size.width)
            .applyHeight(size.height)
    }

}

extension View {

    @ViewBuilder
    func applyWidth(_ sizeConstraint: PaywallComponent.SizeConstraint) -> some View {
        switch sizeConstraint {
        case .fit:
            self
        case .fill:
            self
                .frame(maxWidth: .infinity)
        case .fixed(let value):
            self
                .frame(width: CGFloat(value))
        }
    }

    @ViewBuilder
    func applyHeight(_ sizeConstraint: PaywallComponent.SizeConstraint) -> some View {
        switch sizeConstraint {
        case .fit:
            self
        case .fill:
            self
                .frame(maxHeight: .infinity)
        case .fixed(let value):
            self
                .frame(height: CGFloat(value))
        }
    }

}

extension View {

    func size(_ size: PaywallComponent.Size) -> some View {
        self.modifier(SizeModifier(size: size))
    }

}

#endif
