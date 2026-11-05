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

    /// A zero minimum prevents oversized children from widening Fill ancestors.
    @ViewBuilder
    func applyWidth(_ sizeConstraint: PaywallComponent.SizeConstraint, alignment: Alignment) -> some View {
        switch sizeConstraint {
        case .fit:
            self
        case let .fill(minMax):
            self
                .fill(.horizontal, alignment: alignment)
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
        case .fit:
            self
        case let .fill(minMax):
            self
                .fill(.vertical, alignment: alignment)
                .applyHeightLimits(minMax, alignment: alignment)
        case .fixed(let value):
            self
                .frame(height: CGFloat(value), alignment: alignment)
        case let .relative(_, minMax):
            // WIP: Maybe handle % value here
            self.applyHeightLimits(minMax, alignment: alignment)
        }
    }

    /// Takes all the space proposed along `axis`, like `.frame(minWidth: 0, maxWidth: .infinity)`.
    ///
    /// iOS 17 places a frame's content three times under an unbounded proposal, such as a `ScrollView`'s, and
    /// every nested Fill stack multiplies that until the paywall hangs. ``FillLayout`` places it once.
    @ViewBuilder
    func fill(_ axis: Axis, alignment: Alignment) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
            self.fillFrame(axis, alignment: alignment)
        } else if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            FillLayout(axis: axis, alignment: alignment) {
                self
            }
        } else {
            self.fillFrame(axis, alignment: alignment)
        }
    }

    @ViewBuilder
    private func fillFrame(_ axis: Axis, alignment: Alignment) -> some View {
        switch axis {
        case .horizontal:
            self.frame(minWidth: 0, maxWidth: .infinity, alignment: alignment)
        case .vertical:
            self.frame(minHeight: 0, maxHeight: .infinity, alignment: alignment)
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

/// Lays out its single subview like `.frame(minWidth: 0, maxWidth: .infinity, alignment:)` along `axis`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct FillLayout: Layout {

    let axis: Axis
    let alignment: Alignment

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        let subviewProposal = self.subviewProposal(for: proposal)
        let subviewSize = subview.sizeThatFits(subviewProposal)
        switch self.axis {
        case .horizontal:
            return CGSize(width: subviewProposal.width ?? subviewSize.width, height: subviewSize.height)
        case .vertical:
            return CGSize(width: subviewSize.width, height: subviewProposal.height ?? subviewSize.height)
        }
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else {
            return
        }

        // By size, not `dimensions(in:)`: a stack's alignment guides lay out its whole subtree again.
        let subviewProposal = self.subviewProposal(for: proposal)
        let size = subview.sizeThatFits(subviewProposal)
        let origin = CGPoint(
            x: bounds.minX + Self.fraction(of: self.alignment.horizontal) * (bounds.width - size.width),
            y: bounds.minY + Self.fraction(of: self.alignment.vertical) * (bounds.height - size.height)
        )
        subview.place(at: origin, anchor: .topLeading, proposal: subviewProposal)
    }

    /// The proposal clamped to `minWidth: 0` (or `minHeight: 0`) along the filled axis.
    private func subviewProposal(for proposal: ProposedViewSize) -> ProposedViewSize {
        switch self.axis {
        case .horizontal:
            return ProposedViewSize(width: proposal.width.map { max($0, 0) }, height: proposal.height)
        case .vertical:
            return ProposedViewSize(width: proposal.width, height: proposal.height.map { max($0, 0) })
        }
    }

    /// Where a frame puts its own alignment guide, as a fraction of its length.
    private static func fraction(of alignment: HorizontalAlignment) -> CGFloat {
        switch alignment {
        case .leading: return 0
        case .trailing: return 1
        default: return 0.5
        }
    }

    private static func fraction(of alignment: VerticalAlignment) -> CGFloat {
        switch alignment {
        case .top: return 0
        case .bottom: return 1
        default: return 0.5
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

}

#endif
