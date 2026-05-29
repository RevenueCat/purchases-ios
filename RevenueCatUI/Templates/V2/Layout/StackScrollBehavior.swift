//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackScrollBehavior.swift
//
//  Created by RevenueCat on 5/28/26.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Scroll decisions for Paywalls V2 stacks.
///
/// Z-layer stacks scroll only when overflow explicitly requests scroll and no ancestor already
/// scrolls vertically, avoiding nested vertical `ScrollView`s.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum StackScrollBehavior {

    static func stackScrollingIsEnabled(
        overflow: PaywallComponent.StackComponent.Overflow?,
        isScrollableByDefault: Bool
    ) -> Bool {
        switch overflow {
        case .none:
            return isScrollableByDefault
        case .default:
            return false
        case .scroll:
            return true
        }
    }

    static func shouldApplyZLayerScroll(
        overflow: PaywallComponent.StackComponent.Overflow?,
        isScrollableByDefault: Bool,
        ancestorScrollsVertically: Bool
    ) -> Bool {
        guard !ancestorScrollsVertically else {
            return false
        }

        return self.stackScrollingIsEnabled(
            overflow: overflow,
            isScrollableByDefault: isScrollableByDefault
        )
    }

    /// Sticky-footer paywalls pin main content to the top so a tall body scrolls above a fixed footer.
    static func paywallContentFrameAlignment(
        stickyFooterPresent: Bool,
        rootFrameAlignment: Alignment
    ) -> Alignment {
        stickyFooterPresent ? .top : rootFrameAlignment
    }

    static func shouldExpandPaywallContentToAvailableHeight(
        stickyFooterPresent: Bool,
        rootHeightIsFill: Bool
    ) -> Bool {
        stickyFooterPresent || rootHeightIsFill
    }
}

#endif
