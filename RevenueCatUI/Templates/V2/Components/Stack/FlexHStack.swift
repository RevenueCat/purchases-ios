//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FlexHStack.swift
//
//  Created by Josh Holtz on 11/1/24.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FlexHStack: View {
    let alignment: VerticalAlignment
    let justifyContent: JustifyContent
    let spacing: CGFloat?
    let componentViewModels: [PaywallComponentViewModel]
    let onDismiss: () -> Void

    init(
        alignment: VerticalAlignment,
        spacing: CGFloat?,
        justifyContent: JustifyContent,
        componentViewModels: [PaywallComponentViewModel],
        onDismiss: @escaping () -> Void
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.componentViewModels = componentViewModels
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: self.alignment, spacing: 0) {
            switch justifyContent {
            case .start:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .center:
                Spacer(minLength: 0)
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .end:
                Spacer(minLength: 0)
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    }
                }

            case .spaceBetween:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                        Spacer(minLength: 0)
                    }
                }

            case .spaceAround:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    if index == 0 {
                        FlexSpacer(weight: 1)
                    }
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                        FlexSpacer(weight: 2)
                    } else {
                        FlexSpacer(weight: 1)
                    }
                }

            case .spaceEvenly:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    FlexSpacer(weight: 1)
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    } else {
                        FlexSpacer(weight: 1)
                    }
                }
            }
        }
    }
}

/// A flexbox-style stack used by paywalls that opt in to min/max sizing.
///
/// SwiftUI's built-in stacks include a child's required minimum in their own ideal size. That is useful for
/// ordinary views, but it lets an unsatisfiable minimum widen every Fill ancestor up to the paywall root. This
/// layout keeps the parent's proposed size while placing minimum-sized children sequentially outside its bounds.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct ConstrainedStackLayout: Layout {

    enum Orientation {
        case horizontal
        case vertical
    }

    let orientation: Orientation
    let distribution: PaywallComponent.FlexDistribution
    let crossAxisAlignment: Alignment
    let spacing: CGFloat
    let mainAxisSize: PaywallComponent.SizeConstraint
    let crossAxisSize: PaywallComponent.SizeConstraint

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        return self.measure(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let measurement = self.measure(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )

        for (index, subview) in subviews.enumerated() {
            let childSize = measurement.childSizes[index]
            let mainPosition = measurement.mainPositions[index]
            let crossPosition = self.crossAxisPosition(
                childSize: self.cross(childSize),
                available: self.cross(bounds.size)
            )
            let point: CGPoint
            switch self.orientation {
            case .horizontal:
                point = CGPoint(x: bounds.minX + mainPosition, y: bounds.minY + crossPosition)
            case .vertical:
                point = CGPoint(x: bounds.minX + crossPosition, y: bounds.minY + mainPosition)
            }

            subview.place(at: point, anchor: .topLeading, proposal: ProposedViewSize(childSize))
        }
    }

    static func allocateConstrainedFillSpace(
        availableSpace: CGFloat,
        constraints: [MinMax?],
        floors: [CGFloat]? = nil
    ) -> [CGFloat] {
        var result = Array(repeating: CGFloat.zero, count: constraints.count)
        var remainingIndices = constraints.indices.filter { constraints[$0] != nil }
        var remainingSpace = max(0, availableSpace)

        func minimum(_ index: Int) -> CGFloat {
            return max(CGFloat(constraints[index]?.min ?? 0), floors?[index] ?? 0)
        }

        func maximum(_ index: Int) -> CGFloat {
            guard let maximum = constraints[index]?.max else {
                return .infinity
            }
            return max(CGFloat(maximum), minimum(index))
        }

        while !remainingIndices.isEmpty {
            let equalShare = remainingSpace / CGFloat(remainingIndices.count)
            let minimumConstrained = remainingIndices.filter { equalShare < minimum($0) }
            let constrained = minimumConstrained.isEmpty
                ? remainingIndices.filter { equalShare > maximum($0) }
                : minimumConstrained

            guard !constrained.isEmpty else {
                for index in remainingIndices {
                    result[index] = equalShare
                }
                break
            }

            for index in constrained {
                let allocation = minimumConstrained.isEmpty ? maximum(index) : minimum(index)
                result[index] = allocation
                remainingSpace = max(0, remainingSpace - allocation)
                remainingIndices.removeAll { $0 == index }
            }
        }

        return result
    }

    private struct Measurement {
        let childSizes: [CGSize]
        let mainPositions: [CGFloat]
        let size: CGSize
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func measure(proposal: ProposedViewSize, subviews: Subviews) -> Measurement {
        guard !subviews.isEmpty else {
            return Measurement(childSizes: [], mainPositions: [], size: .zero)
        }

        let sizes = subviews.map { $0[ComponentSizeLayoutValueKey.self]?.size }
        let fillLimits = sizes.map { size -> MinMax? in
            guard let size else { return nil }
            if case let .fill(minMax) = self.mainConstraint(size) {
                return minMax
            }
            return nil
        }
        let gapTotal = self.spacing * CGFloat(max(0, subviews.count - 1))
        let proposedMain = self.main(proposal)
        let isFit = self.mainAxisSize.fitMinMax != nil
        var childSizes = Array(repeating: CGSize.zero, count: subviews.count)
        var nonFillMain = CGFloat.zero

        for index in subviews.indices where fillLimits[index] == nil {
            let consumed = nonFillMain + self.spacing * CGFloat(index)
            // A Fit stack asks children for their intrinsic main-axis size. Scroll views can represent an
            // unbounded proposal as a very large finite value, which must not become a child's Fill height.
            let remaining = isFit ? nil : proposedMain.map { max(0, $0 - consumed) }
            let childProposal = self.proposal(
                main: remaining,
                cross: self.cross(proposal)
            )
            childSizes[index] = subviews[index].sizeThatFits(childProposal)
            nonFillMain += self.main(childSizes[index])
        }

        var fillContentSizes = Array(repeating: CGFloat.zero, count: subviews.count)
        var canHugFillChildren = isFit
        if isFit {
            for index in subviews.indices where fillLimits[index] != nil {
                let contentSize = subviews[index].sizeThatFits(
                    self.proposal(main: nil, cross: self.cross(proposal))
                )
                fillContentSizes[index] = self.main(contentSize)
                canHugFillChildren = canHugFillChildren && fillContentSizes[index] > 0
            }
        }

        let naturalMain = nonFillMain + gapTotal + fillContentSizes.reduce(0, +)
        let targetMain: CGFloat
        if let fitLimits = self.mainAxisSize.fitMinMax, canHugFillChildren {
            targetMain = fitLimits.clamped(min(naturalMain, proposedMain ?? naturalMain))
        } else if let fitLimits = self.mainAxisSize.fitMinMax, !fillLimits.contains(where: { $0 != nil }) {
            targetMain = fitLimits.clamped(min(naturalMain, proposedMain ?? naturalMain))
        } else if let proposedMain {
            targetMain = proposedMain
        } else {
            let minimumFill = Self.allocateConstrainedFillSpace(
                availableSpace: 0,
                constraints: fillLimits
            ).reduce(0, +)
            targetMain = naturalMain + minimumFill
        }

        let fillFloors = canHugFillChildren ? fillContentSizes : nil
        let fillAllocations = Self.allocateConstrainedFillSpace(
            availableSpace: max(0, targetMain - nonFillMain - gapTotal),
            constraints: fillLimits,
            floors: fillFloors
        )
        for index in subviews.indices where fillLimits[index] != nil {
            childSizes[index] = subviews[index].sizeThatFits(
                self.proposal(main: fillAllocations[index], cross: self.cross(proposal))
            )
        }

        self.remeasureCrossAxisFillChildren(
            subviews: subviews,
            sizes: sizes,
            childSizes: &childSizes,
            proposal: proposal
        )

        let naturalCrossSize = childSizes.map(self.cross).max() ?? 0
        let crossSize = self.resolvedCrossSize(natural: naturalCrossSize, proposed: self.cross(proposal))
        let positions = self.mainPositions(
            childSizes: childSizes.map(self.main),
            available: targetMain
        )
        let resolvedSize: CGSize
        switch self.orientation {
        case .horizontal:
            resolvedSize = CGSize(width: targetMain, height: crossSize)
        case .vertical:
            resolvedSize = CGSize(width: crossSize, height: targetMain)
        }

        return Measurement(childSizes: childSizes, mainPositions: positions, size: resolvedSize)
    }

    private func resolvedCrossSize(natural: CGFloat, proposed: CGFloat?) -> CGFloat {
        switch self.crossAxisSize {
        case .fill(let minMax):
            return minMax.clamped(proposed ?? natural)
        case .fixed(let value):
            return CGFloat(value)
        case .fit(_, let minMax):
            return minMax.clamped(min(natural, proposed ?? natural))
        case .relative(_, let minMax):
            return minMax.clamped(proposed ?? natural)
        }
    }

    private func remeasureCrossAxisFillChildren(
        subviews: Subviews,
        sizes: [PaywallComponent.Size?],
        childSizes: inout [CGSize],
        proposal: ProposedViewSize
    ) {
        guard self.cross(proposal) == nil else { return }

        let crossFillLimits = sizes.map { size -> MinMax? in
            guard let size else { return nil }
            if case let .fill(minMax) = self.crossConstraint(size) {
                return minMax
            }
            return nil
        }
        guard crossFillLimits.contains(where: { $0 != nil }) else { return }

        // Under a scroll view, a cross-axis Fill frame can report an arbitrarily large ideal size.
        // Derive the finite cross-axis target from non-Fill siblings, then remeasure Fill children to it.
        let contentCross = childSizes.indices
            .filter { crossFillLimits[$0] == nil }
            .map { self.cross(childSizes[$0]) }
            .max() ?? 0
        let minimumCross = crossFillLimits.compactMap { $0?.min }.map { CGFloat($0) }.max() ?? 0
        let targetCross = max(contentCross, minimumCross)

        for index in subviews.indices where crossFillLimits[index] != nil {
            childSizes[index] = subviews[index].sizeThatFits(
                self.proposal(main: self.main(childSizes[index]), cross: targetCross)
            )
        }
    }

    private func mainPositions(childSizes: [CGFloat], available: CGFloat) -> [CGFloat] {
        let content = childSizes.reduce(0, +) + self.spacing * CGFloat(max(0, childSizes.count - 1))
        let extra = available - content
        let positiveExtra = max(0, extra)
        let leading: CGFloat
        let distributedGap: CGFloat

        switch self.distribution {
        case .start:
            leading = 0
            distributedGap = 0
        case .center:
            leading = extra / 2
            distributedGap = 0
        case .end:
            leading = extra
            distributedGap = 0
        case .spaceBetween:
            leading = 0
            distributedGap = childSizes.count > 1 ? positiveExtra / CGFloat(childSizes.count - 1) : 0
        case .spaceAround:
            distributedGap = positiveExtra / CGFloat(childSizes.count)
            leading = distributedGap / 2
        case .spaceEvenly:
            distributedGap = positiveExtra / CGFloat(childSizes.count + 1)
            leading = distributedGap
        }

        var result: [CGFloat] = []
        var position = leading
        for childSize in childSizes {
            result.append(position)
            position += childSize + self.spacing + distributedGap
        }
        return result
    }

    private func crossAxisPosition(childSize: CGFloat, available: CGFloat) -> CGFloat {
        switch self.orientation {
        case .horizontal:
            if self.crossAxisAlignment.vertical == .top { return 0 }
            if self.crossAxisAlignment.vertical == .bottom { return available - childSize }
        case .vertical:
            if self.crossAxisAlignment.horizontal == .leading { return 0 }
            if self.crossAxisAlignment.horizontal == .trailing { return available - childSize }
        }
        return (available - childSize) / 2
    }

    private func mainConstraint(_ size: PaywallComponent.Size) -> PaywallComponent.SizeConstraint {
        switch self.orientation {
        case .horizontal: return size.width
        case .vertical: return size.height
        }
    }

    private func crossConstraint(_ size: PaywallComponent.Size) -> PaywallComponent.SizeConstraint {
        switch self.orientation {
        case .horizontal: return size.height
        case .vertical: return size.width
        }
    }

    private func main(_ proposal: ProposedViewSize) -> CGFloat? {
        switch self.orientation {
        case .horizontal: return proposal.width
        case .vertical: return proposal.height
        }
    }

    private func cross(_ proposal: ProposedViewSize) -> CGFloat? {
        switch self.orientation {
        case .horizontal: return proposal.height
        case .vertical: return proposal.width
        }
    }

    private func main(_ size: CGSize) -> CGFloat {
        switch self.orientation {
        case .horizontal: return size.width
        case .vertical: return size.height
        }
    }

    private func cross(_ size: CGSize) -> CGFloat {
        switch self.orientation {
        case .horizontal: return size.height
        case .vertical: return size.width
        }
    }

    private func proposal(main: CGFloat?, cross: CGFloat?) -> ProposedViewSize {
        switch self.orientation {
        case .horizontal: return ProposedViewSize(width: main, height: cross)
        case .vertical: return ProposedViewSize(width: cross, height: main)
        }
    }

}

private extension PaywallComponent.SizeConstraint {

    var fitMinMax: MinMax? {
        guard case let .fit(_, minMax) = self else { return nil }
        return minMax
    }

}

#endif
