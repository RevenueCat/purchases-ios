//
//  DefaultPaywallViewTests.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OtherPaywallViewTests: BaseSnapshotTest {

    func testLoadingPaywallView() {
        LoadingPaywallView(mode: .fullScreen, displayCloseButton: false, shimmer: false)
            .recordSnapshot(size: Self.fullScreenSize)
    }

    func testLoadingFooterPaywallView() {
        LoadingPaywallView(mode: .footer, displayCloseButton: false, shimmer: false)
            .recordSnapshot(size: Self.footerSize)
    }

    func testLoadingCondensedFooterPaywallView() {
        LoadingPaywallView(mode: .condensedFooter, displayCloseButton: false, shimmer: false)
            .recordSnapshot(size: Self.footerSize)
    }

}

#endif
