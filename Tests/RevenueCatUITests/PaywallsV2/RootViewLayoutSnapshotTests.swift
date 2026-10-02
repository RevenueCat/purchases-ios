//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootViewLayoutSnapshotTests.swift
//

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) && !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class RootViewLayoutSnapshotTests: BaseSnapshotTest {

    override func setUpWithError() throws {
        try super.setUpWithError()

        // These snapshots render inconsistently on iOS 15.
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Snapshot is inconsistent on iOS 15")
        }
    }

    func testStickyFooterRootZLayerOnIPadFormSheet() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    /// Missing overflow retains the legacy inherited root z-layer default in the sibling footer.
    func testLegacyRootZLayerWithZLayerFooterOnIPadFormSheet() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel(footerIsZLayer: true)
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
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

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
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

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
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

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
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

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    func testStickyFooterOnIPadCardWithoutBottomSafeArea() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 0, trailing: 0)
        )
        .environment(\.userInterfaceIdiom, .pad)

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    /// Scrolled to the bottom, the last row must still clear the sticky footer once the footer
    /// gains its minimum padding.
    func testStickyFooterReservesScrollSpaceOnIPadCard() throws {
        // defaultScrollAnchor is an iOS 17 SDK symbol, so Xcode 14 cannot compile the call at all.
        #if swift(>=5.9)
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) else {
            throw XCTSkip("defaultScrollAnchor requires iOS 17")
        }

        let viewModel = try PaywallsV2LayoutFixtures.makeTransparentFooterOverScrollableContentViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 0, trailing: 0)
        )
        .environment(\.userInterfaceIdiom, .pad)
        .defaultScrollAnchor(.bottom)

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    func testStickyFooterRootZLayerOnIPhoneFullScreen() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: Self.fullScreenSize
        )

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testTransparentFooterOverlapsScrollableContent() throws {
        let view = try makeFullScreenSnapshotView(
            PaywallsV2LayoutFixtures.makeTransparentFooterOverScrollableContentViewModel
        )

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testSmallBodyCentersAboveFooter() throws {
        let view = try makeFullScreenSnapshotView(PaywallsV2LayoutFixtures.makeSmallCenteredBodyAboveFooterViewModel)

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testHeaderAndFooterStepReservesHeaderClearance() throws {
        let view = try makeFullScreenSnapshotView(PaywallsV2LayoutFixtures.makeHeaderAndFooterViewModel)

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    private func makeFullScreenSnapshotView(_ makeViewModel: () throws -> RootViewModel) throws -> some View {
        PaywallsV2LayoutFixtures.makeRootView(viewModel: try makeViewModel(), size: Self.fullScreenSize)
    }

}

#endif
