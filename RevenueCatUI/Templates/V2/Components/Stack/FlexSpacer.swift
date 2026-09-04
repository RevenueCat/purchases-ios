//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FlexSpacer.swift
//
//  Created by Josh Holtz on 11/1/24.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// A weighted spacer that simulates flex layout spacing behavior.
/// Creates multiple `Spacer()` instances to achieve proportional space distribution.
/// For example, `FlexSpacer(weight: 2)` will take twice as much space as `FlexSpacer(weight: 1)`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal struct FlexSpacer: View {
    let weight: Int
    let axis: Axis?
    let lengthPerWeight: CGFloat?

    init(weight: Int, axis: Axis? = nil, lengthPerWeight: CGFloat? = nil) {
        self.weight = weight
        self.axis = axis
        self.lengthPerWeight = lengthPerWeight
    }

    /// Fit stacks use fixed weighted spacers so a larger parent proposal cannot turn them into fill.
    static func lengthPerWeight(
        fitMinimum: CGFloat?,
        contentLength: CGFloat,
        spacing: CGFloat?,
        componentCount: Int,
        totalWeight: Int
    ) -> CGFloat? {
        guard let fitMinimum else {
            return nil
        }

        let totalSpacing = (spacing ?? 0) * CGFloat(max(componentCount - 1, 0))
        let availableSpace = max(fitMinimum - contentLength - totalSpacing, 0)

        return totalWeight > 0 ? availableSpace / CGFloat(totalWeight) : 0
    }

    @ViewBuilder
    var body: some View {
        if let axis, let lengthPerWeight {
            switch axis {
            case .horizontal:
                Spacer(minLength: 0).frame(width: lengthPerWeight * CGFloat(weight))
            case .vertical:
                Spacer(minLength: 0).frame(height: lengthPerWeight * CGFloat(weight))
            }
        } else {
            ForEach(0..<weight, id: \.self) { _ in
                Spacer(minLength: 0)
            }
        }
    }
}

#endif
