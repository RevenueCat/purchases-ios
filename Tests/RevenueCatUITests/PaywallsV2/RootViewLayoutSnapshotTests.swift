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
import XCTest

#if !os(tvOS) && !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class RootViewLayoutSnapshotTests: BaseSnapshotTest {

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

}

#endif
