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

    func body(content: Content) -> some View {
        content
            .applyWidth(size.width, alignment: hortizontalAlignment)
            .applyHeight(size.height, alignment: verticalAlignment)
    }

}

extension View {

    @ViewBuilder
    func applyWidth(_ sizeConstraint: PaywallComponent.SizeConstraint, alignment: Alignment) -> some View {
        switch sizeConstraint {
        case let .fit(_, minMax):
            self.applyFitWidthLimits(minMax, alignment: alignment)
        case let .fill(minMax):
            self
                .frame(maxWidth: .infinity, alignment: alignment)
                .applyWidthLimits(minMax, alignment: alignment)
        case .fixed(let value):
            self
                .frame(width: CGFloat(value), alignment: alignment)
        case let .relative(_, minMax):
            // WIP: Maybe handle % value here
            self.applyWidthLimits(minMax, alignment: alignment)
        }
    }

    @ViewBuilder
    func applyHeight(_ sizeConstraint: PaywallComponent.SizeConstraint, alignment: Alignment) -> some View {
        switch sizeConstraint {
        case let .fit(_, minMax):
            self.applyFitHeightLimits(minMax, alignment: alignment)
        case let .fill(minMax):
            self
                .frame(maxHeight: .infinity, alignment: alignment)
                .applyHeightLimits(minMax, alignment: alignment)
        case .fixed(let value):
            self
                .frame(height: CGFloat(value), alignment: alignment)
        case let .relative(_, minMax):
            // WIP: Maybe handle % value here
            self.applyHeightLimits(minMax, alignment: alignment)
        }
    }

    @ViewBuilder
    private func applyFitWidthLimits(_ minMax: MinMax, alignment: Alignment) -> some View {
        if minMax.hasLimit {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                IntrinsicSizeLayout(axis: .horizontal, minMax: minMax) {
                    self.frame(maxWidth: .infinity, alignment: alignment)
                }
            } else {
                self
                    .frame(minWidth: minMax.minDimension, alignment: alignment)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: minMax.effectiveMaxDimension, alignment: alignment)
                    .fixedSize(horizontal: true, vertical: false)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    private func applyFitHeightLimits(_ minMax: MinMax, alignment: Alignment) -> some View {
        if minMax.hasLimit {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                IntrinsicSizeLayout(axis: .vertical, minMax: minMax) {
                    self.frame(maxHeight: .infinity, alignment: alignment)
                }
            } else {
                self
                    .frame(minHeight: minMax.minDimension, alignment: alignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: minMax.effectiveMaxDimension, alignment: alignment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            self
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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct IntrinsicSizeLayout: Layout {

    let axis: Axis
    let minMax: MinMax

    /// Measures without a proposal on the fit axis, then proposes the bounded result back to the content.
    /// The second pass lets flexible descendants consume a minimum without letting a larger parent proposal
    /// expand the fit component to its maximum.
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        var intrinsicProposal = proposal
        switch self.axis {
        case .horizontal:
            intrinsicProposal.width = nil
        case .vertical:
            intrinsicProposal.height = nil
        }

        let intrinsicSize = subview.sizeThatFits(intrinsicProposal)
        var resolvedProposal = proposal

        switch self.axis {
        case .horizontal:
            resolvedProposal.width = self.resolved(
                intrinsic: intrinsicSize.width,
                available: proposal.width
            )
        case .vertical:
            resolvedProposal.height = self.resolved(
                intrinsic: intrinsicSize.height,
                available: proposal.height
            )
        }

        var resolvedSize = subview.sizeThatFits(resolvedProposal)
        switch self.axis {
        case .horizontal:
            resolvedSize.width = resolvedProposal.width ?? resolvedSize.width
        case .vertical:
            resolvedSize.height = resolvedProposal.height ?? resolvedSize.height
        }

        return resolvedSize
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        subviews.first?.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(bounds.size)
        )
    }

    private func resolved(intrinsic: CGFloat, available: CGFloat?) -> CGFloat {
        return self.minMax.clamped(min(intrinsic, available ?? intrinsic))
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

}

#endif
