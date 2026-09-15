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

    @ViewBuilder
    func body(content: Content) -> some View {
        if let fitLimits = FitLimits(size: self.size) {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                FitSizeLayout(limits: fitLimits, alignment: self.alignment) {
                    content
                        .applyFitLayoutWidth(self.size.width, alignment: self.hortizontalAlignment)
                        .applyFitLayoutHeight(self.size.height, alignment: self.verticalAlignment)
                }
            } else {
                self.applyFrames(to: content)
            }
        } else {
            self.applyFrames(to: content)
        }
    }

    private var alignment: Alignment {
        Alignment(
            horizontal: self.hortizontalAlignment.horizontal,
            vertical: self.verticalAlignment.vertical
        )
    }

    private func applyFrames(to content: Content) -> some View {
        content
            .applyWidth(self.size.width, alignment: self.hortizontalAlignment)
            .applyHeight(self.size.height, alignment: self.verticalAlignment)
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

    /// Fallback for OS versions without `Layout`. A minimum provides a finite intrinsic target, so measure
    /// around it before applying the maximum. Max-only widths keep the regular frame behavior so text wraps.
    @ViewBuilder
    func applyFitWidthLimits(_ minMax: MinMax, alignment: Alignment) -> some View {
        if minMax.min != nil {
            self
                .frame(minWidth: minMax.minDimension, alignment: alignment)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: minMax.effectiveMaxDimension, alignment: alignment)
                .fixedSize(horizontal: true, vertical: false)
        } else {
            self.applyWidthLimits(minMax, alignment: alignment)
        }
    }

    /// Fallback for OS versions without `Layout`: measure the content at its intrinsic height, then clamp.
    /// The width proposal is preserved so text still wraps; the minimum is not proposed back to the content,
    /// so flexible children are aligned inside the minimum instead of stretched to it.
    @ViewBuilder
    func applyFitHeightLimits(_ minMax: MinMax, alignment: Alignment) -> some View {
        if minMax.hasLimit {
            self
                .frame(minHeight: minMax.minDimension, alignment: alignment)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: minMax.effectiveMaxDimension, alignment: alignment)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            self
        }
    }

    /// Inside `FitSizeLayout` a limited fit axis must stay flexible so the layout can propose the clamped
    /// size back to the content, letting fill children and flex spacers consume the minimum.
    @ViewBuilder
    fileprivate func applyFitLayoutWidth(
        _ sizeConstraint: PaywallComponent.SizeConstraint,
        alignment: Alignment
    ) -> some View {
        if sizeConstraint.fitLimits != nil {
            self.frame(maxWidth: .infinity, alignment: alignment)
        } else {
            self.applyWidth(sizeConstraint, alignment: alignment)
        }
    }

    @ViewBuilder
    fileprivate func applyFitLayoutHeight(
        _ sizeConstraint: PaywallComponent.SizeConstraint,
        alignment: Alignment
    ) -> some View {
        if sizeConstraint.fitLimits != nil {
            self.frame(maxHeight: .infinity, alignment: alignment)
        } else {
            self.applyHeight(sizeConstraint, alignment: alignment)
        }
    }

}

/// The min/max limits of each axis that is `fit`, or `nil` when neither axis needs fit clamping.
private struct FitLimits {

    let width: MinMax?
    let height: MinMax?

    init?(size: PaywallComponent.Size) {
        self.width = size.width.fitLimits
        self.height = size.height.fitLimits

        if self.width == nil && self.height == nil {
            return nil
        }
    }

}

/// Sizes fit content to its intrinsic size clamped to the configured min/max.
///
/// `frame(minWidth:maxWidth:)` clamps the *proposal*, so flexible content grows to the maximum whenever the
/// parent offers more space. This layout measures the content without a proposal on each fit axis first,
/// clamps that intrinsic size, and then proposes the clamped size back. The second pass is what lets fill
/// children and flex spacers consume a minimum without a larger parent proposal inflating the content to
/// its maximum.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct FitSizeLayout: Layout {

    let limits: FitLimits
    let alignment: Alignment

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        var intrinsicProposal = proposal
        if self.limits.width != nil {
            intrinsicProposal.width = nil
        }
        if self.limits.height != nil {
            intrinsicProposal.height = nil
        }
        var intrinsicSize = subview.sizeThatFits(intrinsicProposal)

        var resolvedProposal = proposal
        if let width = self.limits.width {
            resolvedProposal.width = Self.resolve(
                intrinsic: intrinsicSize.width,
                available: proposal.width,
                limits: width
            )
            if self.limits.height != nil {
                // Width drives wrapping, so when both axes are limited the height clamp must see the height
                // of the content at the resolved width rather than its unwrapped, single-line height.
                intrinsicSize = subview.sizeThatFits(
                    ProposedViewSize(width: resolvedProposal.width, height: nil)
                )
            }
        }
        if let height = self.limits.height {
            resolvedProposal.height = Self.resolve(
                intrinsic: intrinsicSize.height,
                available: proposal.height,
                limits: height
            )
        }

        // Clamp what the content actually measured rather than forcing the proposal: fixed children larger
        // than the maximum must not grow the box (they overflow instead), but rigid content that only exceeds
        // the parent's proposal keeps its real size, exactly like an unconstrained fit axis.
        var size = subview.sizeThatFits(resolvedProposal)
        if let width = self.limits.width {
            size.width = width.clamped(size.width)
        }
        if let height = self.limits.height {
            size.height = height.clamped(size.height)
        }

        return size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // Anchor like `frame(alignment:)` so content that overflows the maximum spills symmetrically.
        let anchor = self.alignment.unitPoint
        subviews.first?.place(
            at: CGPoint(
                x: bounds.minX + bounds.width * anchor.x,
                y: bounds.minY + bounds.height * anchor.y
            ),
            anchor: anchor,
            proposal: ProposedViewSize(bounds.size)
        )
    }

    /// Fit never exceeds what the parent offers unless the minimum requires it, matching an unconstrained fit
    /// axis which is simply proposed the parent's size.
    private static func resolve(intrinsic: CGFloat, available: CGFloat?, limits: MinMax) -> CGFloat {
        return limits.clamped(min(intrinsic, available ?? intrinsic))
    }

}

private extension Alignment {

    // swiftlint:disable identifier_name
    var unitPoint: UnitPoint {
        let x: CGFloat
        switch self.horizontal {
        case .leading: x = 0
        case .trailing: x = 1
        default: x = 0.5
        }

        let y: CGFloat
        switch self.vertical {
        case .top: y = 0
        case .bottom: y = 1
        default: y = 0.5
        }

        return UnitPoint(x: x, y: y)
    }
    // swiftlint:enable identifier_name

}

private extension PaywallComponent.SizeConstraint {

    var fitLimits: MinMax? {
        guard case let .fit(_, minMax) = self, minMax.hasLimit else {
            return nil
        }

        return minMax
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
