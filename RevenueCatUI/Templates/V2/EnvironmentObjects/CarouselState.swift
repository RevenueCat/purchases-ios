//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselState.swift
//
//  Created by RevenueCat on 2/2/26.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Tracks carousel pagination state to enable lazy loading of content on inactive pages.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselState: Equatable {

    /// The currently active page index in the carousel's data array.
    let activeIndex: Int

    /// This page's index in the carousel's data array.
    let pageIndex: Int

    /// The number of original pages (before copies for looping).
    let originalCount: Int

    /// Whether this page is the currently visible page.
    /// For looping carousels, compares original page indices since the same content exists at multiple data indices.
    var isActive: Bool {
        guard originalCount > 0 else { return activeIndex == pageIndex }
        return activeIndex % originalCount == pageIndex % originalCount
    }

    /// Whether this page is active or adjacent to the active page in the data array.
    /// This matches the visible "side" pages in the carousel strip.
    var isActiveOrNeighbor: Bool {
        return abs(activeIndex - pageIndex) <= 1
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CarouselStateKey: EnvironmentKey {
    static let defaultValue: CarouselState? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var carouselState: CarouselState? {
        get { self[CarouselStateKey.self] }
        set { self[CarouselStateKey.self] = newValue }
    }

}

#endif
