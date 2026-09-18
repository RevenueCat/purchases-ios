//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ApplySizing.swift
//
//  Created by Jacob Zivan Rakidzich on 9/12/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @ViewBuilder
    func applyMediaWidth(size: PaywallComponent.Size, subtracting contentInsets: EdgeInsets) -> some View {
        switch size.width {
        case let .fit(_, minMax):
            self.applyWidthLimits(minMax, alignment: .center)
        case let .fill(minMax):
            self
                .frame(maxWidth: .infinity)
                .applyWidthLimits(minMax, alignment: .center)
        case .fixed(let value):
            self.frame(width: max(0, CGFloat(value) - contentInsets.leading - contentInsets.trailing))
        case let .relative(_, minMax):
            self.applyWidthLimits(minMax, alignment: .center)
        }
    }

    @ViewBuilder
    func applyMediaHeight(
        size: PaywallComponent.Size,
        aspectRatio: Double,
        subtracting contentInsets: EdgeInsets
    ) -> some View {
        switch size.height {
        case let .fit(_, minMax):
            switch size.width {
            case .fit:
                self.applyHeightLimits(minMax, alignment: .center)
            case .fill:
                self.applyHeightLimits(minMax, alignment: .center)
            case .fixed(let value):
                // This is the only change versus the regular .size() modifier.
                // When the image or videoa has height=fit and fixed width, we manually set a
                // fixed height according to the aspect ratio.
                // Otherwise the view would grow vertically to occupy available space.
                // See "Image streching vertically" preview
                let contentWidth = max(0, CGFloat(value) - contentInsets.leading - contentInsets.trailing)
                self.frame(height: minMax.clamped(contentWidth / CGFloat(aspectRatio)))
            case .relative:
                self.applyHeightLimits(minMax, alignment: .center)
            }
        case let .fill(minMax):
            self
                .frame(maxHeight: .infinity)
                .applyHeightLimits(minMax, alignment: .center)
        case .fixed(let value):
            self.frame(height: max(0, CGFloat(value) - contentInsets.top - contentInsets.bottom))
        case let .relative(_, minMax):
            self.applyHeightLimits(minMax, alignment: .center)
        }
    }

}

#endif
