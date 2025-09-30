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

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @ViewBuilder
    func applyMediaWidth(size: PaywallComponent.Size) -> some View {
        switch size.width {
        case .fit:
            self
        case .fill:
            self.frame(maxWidth: .infinity)
        case .fixed(let value):
            self.frame(width: Double(value))
        default:
            self
        }
    }

    @ViewBuilder
    func applyMediaHeight(size: PaywallComponent.Size, aspectRatio: Double) -> some View {
        switch size.height {
        case .fit:
            switch size.width {
            case .fit:
                self
            case .fill:
                self
            case .fixed(let value):
                // This is the only change versus the regular .size() modifier.
                // When the image or videoa has height=fit and fixed width, we manually set a
                // fixed height according to the aspect ratio.
                // Otherwise the view would grow vertically to occupy available space.
                // See "Image streching vertically" preview
                self.frame(height: Double(value) / aspectRatio)
            default:
                self
            }
        case .fill:
            self.frame(maxHeight: .infinity)
        case .fixed(let value):
            self.frame(height: Double(value))
        default:
            self
        }
    }

}
