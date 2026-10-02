//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootViewScrollSnapshotTests.swift
//

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) && !os(watchOS) && !os(macOS)

// These snapshots are recorded in CI and compared in Emerge instead of stored in git.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class RootViewScrollSnapshotTests: BaseSnapshotTest {

    override func setUpWithError() throws {
        try super.setUpWithError()

        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Snapshot is inconsistent on iOS 15")
        }
    }

    /// Missing overflow retains the legacy inherited root z-layer default in the sibling footer.
    func testLegacyRootZLayerWithZLayerFooterOnIPadFormSheet() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel(footerIsZLayer: true)
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )

        recordLayoutSnapshot(view)
    }

    /// An explicit default overflow must keep the tall hero fixed even when a bottom scroll anchor is requested.
    func testExplicitDefaultRootZLayerOnIPadFormSheet() throws {
        #if swift(>=5.9)
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) else {
            throw XCTSkip("defaultScrollAnchor requires iOS 17")
        }
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel(overflow: .default)
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )
        .defaultScrollAnchor(.bottom)

        recordLayoutSnapshot(view)
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    func testScrollingZLayerChildInsideExplicitDefaultRoot() throws {
        #if swift(>=5.9)
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) else {
            throw XCTSkip("defaultScrollAnchor requires iOS 17")
        }
        let viewModel = try PaywallsV2LayoutFixtures.makeNonScrollingRootWithZLayerChildViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )
        .defaultScrollAnchor(.bottom)

        recordLayoutSnapshot(view)
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    func testDefaultZLayerChildInsideExplicitDefaultRootDoesNotScroll() throws {
        #if swift(>=5.9)
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) else {
            throw XCTSkip("defaultScrollAnchor requires iOS 17")
        }
        let viewModel = try PaywallsV2LayoutFixtures.makeNonScrollingRootWithZLayerChildViewModel(childOverflow: nil)
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )
        .defaultScrollAnchor(.bottom)

        recordLayoutSnapshot(view)
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    func testWidthRuleZLayerRootPreservesDefaultScrolling() throws {
        #if swift(>=5.9)
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) else {
            throw XCTSkip("defaultScrollAnchor requires iOS 17")
        }
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel(
            rootChangesToZLayerByWidthRule: true
        )
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )
        .environment(\.paywallWindowSize, PaywallsV2LayoutFixtures.iPadFormSheetSize)
        .defaultScrollAnchor(.bottom)

        recordLayoutSnapshot(view)
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    private func recordLayoutSnapshot<V: View>(_ view: V) {
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            issue.type == .assertionFailure &&
                issue.compactDescription.hasPrefix("Record mode is on. Automatically recorded snapshot:")
        }
        XCTExpectFailure("Snapshot recording writes an image instead of comparing a baseline", options: options) {
            view.recordSnapshot(size: PaywallsV2LayoutFixtures.iPadFormSheetSize)
        }
    }

}

#endif
