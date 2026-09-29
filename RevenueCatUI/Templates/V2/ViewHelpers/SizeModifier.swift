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

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

struct SizeModifier: ViewModifier {

    var size: PaywallComponent.Size
    var hortizontalAlignment: Alignment
    var verticalAlignment: Alignment
    var contentInsets: EdgeInsets = .init()

    func body(content: Content) -> some View {
        content
            .applyWidth(
                size.width,
                alignment: hortizontalAlignment,
                fixedDimensionInset: contentInsets.leading + contentInsets.trailing
            )
            .applyHeight(
                size.height,
                alignment: verticalAlignment,
                fixedDimensionInset: contentInsets.top + contentInsets.bottom
            )
    }

}

extension View {

    /// A zero minimum prevents oversized children from widening Fill ancestors.
    @ViewBuilder
    func applyWidth(
        _ sizeConstraint: PaywallComponent.SizeConstraint,
        alignment: Alignment,
        fixedDimensionInset: CGFloat = 0
    ) -> some View {
        switch sizeConstraint {
        case let .fit(_, minMax):
            self.applyWidthLimits(minMax, alignment: alignment)
        case let .fill(minMax):
            self
                .frame(minWidth: 0, maxWidth: .infinity, alignment: alignment)
                .applyWidthLimits(minMax, alignment: alignment)
        case .fixed(let value):
            self
                .frame(width: max(0, CGFloat(value) - fixedDimensionInset), alignment: alignment)
        case let .relative(_, minMax):
            // WIP: Maybe handle % value here
            self.applyWidthLimits(minMax, alignment: alignment)
        }
    }

    @ViewBuilder
    func applyHeight(
        _ sizeConstraint: PaywallComponent.SizeConstraint,
        alignment: Alignment,
        fixedDimensionInset: CGFloat = 0
    ) -> some View {
        switch sizeConstraint {
        case let .fit(_, minMax):
            self.applyHeightLimits(minMax, alignment: alignment)
        case let .fill(minMax):
            self
                .frame(minHeight: 0, maxHeight: .infinity, alignment: alignment)
                .applyHeightLimits(minMax, alignment: alignment)
        case .fixed(let value):
            self
                .frame(height: max(0, CGFloat(value) - fixedDimensionInset), alignment: alignment)
        case let .relative(_, minMax):
            // WIP: Maybe handle % value here
            self.applyHeightLimits(minMax, alignment: alignment)
        }
    }

    @ViewBuilder
    func applyWidthLimits(_ minMax: MinMax, alignment: Alignment) -> some View {
        if minMax.hasLimit {
            self.frame(
                minWidth: minMax.minDimension,
                maxWidth: minMax.effectiveMaxDimension,
                alignment: alignment
            )
        } else {
            self
        }
    }

    @ViewBuilder
    func applyHeightLimits(_ minMax: MinMax, alignment: Alignment) -> some View {
        if minMax.hasLimit {
            self.frame(
                minHeight: minMax.minDimension,
                maxHeight: minMax.effectiveMaxDimension,
                alignment: alignment
            )
        } else {
            self
        }
    }

}

extension MinMax {

    fileprivate var hasLimit: Bool {
        return self != .null
    }

    fileprivate var minDimension: CGFloat? {
        return self.min.map { CGFloat($0) }
    }

    /// Aligned with CSS - minimum gets precedence when it is greater than the maximum.
    fileprivate var effectiveMaxDimension: CGFloat? {
        switch (self.min, self.max) {
        case let (.some(minimum), .some(maximum)):
            return CGFloat(Swift.max(minimum, maximum))
        case let (_, .some(maximum)):
            return CGFloat(maximum)
        default:
            return nil
        }
    }

    func clamped(_ value: CGFloat) -> CGFloat {
        if let minimum = self.minDimension, value < minimum {
            return minimum
        }

        if let maximum = self.effectiveMaxDimension, value > maximum {
            return maximum
        }

        return value
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

    func size(_ size: PaywallComponent.Size,
              subtracting contentInsets: EdgeInsets,
              horizontalAlignment: Alignment = .center,
              verticalAlignment: Alignment = .center) -> some View {
        self.modifier(SizeModifier(size: size,
                                   hortizontalAlignment: horizontalAlignment,
                                   verticalAlignment: verticalAlignment,
                                   contentInsets: contentInsets))
    }

}

#endif
