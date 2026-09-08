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

/// Points a media asset takes up when both dimensions are `fit`: its pixel size read as points, the
/// way the paywall editor previews it. Callers still cap it to the space available.
enum MediaIntrinsicSize {

    static func points(pixelWidth: Int, pixelHeight: Int) -> CGSize {
        return CGSize(width: max(1, pixelWidth), height: max(1, pixelHeight))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// - Parameter intrinsicSize: the asset's own size in points, see ``MediaIntrinsicSize``.
    @ViewBuilder
    func applyMediaWidth(size: PaywallComponent.Size, intrinsicSize: CGSize) -> some View {
        switch size.width {
        case let .fit(_, minMax):
            switch size.height {
            case .fit:
                // Both axes fit: the asset is drawn at its own size, never wider than its parent.
                self
                    .frame(maxWidth: intrinsicSize.width)
                    .applyWidthLimits(minMax, alignment: .center)
            case .fixed, .fill, .relative:
                self.applyWidthLimits(minMax, alignment: .center)
            }
        case let .fill(minMax):
            self
                .frame(maxWidth: .infinity)
                .applyWidthLimits(minMax, alignment: .center)
        case .fixed(let value):
            self.frame(width: Double(value))
        case let .relative(_, minMax):
            self.applyWidthLimits(minMax, alignment: .center)
        }
    }

    /// - Parameter intrinsicSize: the asset's own size in points, see ``MediaIntrinsicSize``.
    @ViewBuilder
    func applyMediaHeight(size: PaywallComponent.Size, intrinsicSize: CGSize) -> some View {
        switch size.height {
        case let .fit(_, minMax):
            switch size.width {
            case .fit:
                self
                    .frame(maxHeight: intrinsicSize.height)
                    .applyHeightLimits(minMax, alignment: .center)
            case .fill:
                self.applyHeightLimits(minMax, alignment: .center)
            case .fixed(let value):
                // This is the only change versus the regular .size() modifier.
                // When the image or videoa has height=fit and fixed width, we manually set a
                // fixed height according to the aspect ratio.
                // Otherwise the view would grow vertically to occupy available space.
                // See "Image streching vertically" preview
                self.frame(height: minMax.clamped(Double(value) / intrinsicSize.aspectRatio))
            case .relative:
                self.applyHeightLimits(minMax, alignment: .center)
            }
        case let .fill(minMax):
            self
                .frame(maxHeight: .infinity)
                .applyHeightLimits(minMax, alignment: .center)
        case .fixed(let value):
            self.frame(height: Double(value))
        case let .relative(_, minMax):
            self.applyHeightLimits(minMax, alignment: .center)
        }
    }

}

private extension CGSize {

    var aspectRatio: Double {
        return self.width / self.height
    }

}

#endif
