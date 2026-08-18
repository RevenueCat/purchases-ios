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
