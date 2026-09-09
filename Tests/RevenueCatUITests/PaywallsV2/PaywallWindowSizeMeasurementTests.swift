//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallWindowSizeMeasurementTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

/// Pins that `measurePaywallWindowSize()` is layout-neutral: the paywall content inside it keeps
/// the exact size and safe area insets it would have without the wrapper. `LoadedPaywallsV2View`'s
/// own `GeometryReader` feeds `proxy.safeAreaInsets` to header images and sticky footers, so a
/// wrapper that consumed or zeroed the safe area would push content under the notch or home
/// indicator.
@available(iOS 15.0, *)
final class PaywallWindowSizeMeasurementTests: TestCase {

    private static let windowSize = CGSize(width: 390, height: 844)
    private static let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)

    @MainActor
    func testWrapperDoesNotChangeInnerGeometry() throws {
        let bare = try Self.capturedGeometry { probe in probe }
        let wrapped = try Self.capturedGeometry { probe in probe.measurePaywallWindowSize() }

        // Sanity: the harness applies real insets, so an inset-zeroing bug can't pass vacuously.
        // The simulator's own device insets stack on top of `additionalSafeAreaInsets`, so
        // assert a floor rather than an exact value.
        expect(bare.insets.top) >= Self.safeArea.top
        expect(bare.insets.bottom) >= Self.safeArea.bottom

        expect(wrapped.size) == bare.size
        expect(wrapped.insets) == bare.insets
    }

    @MainActor
    func testWrapperPublishesTheProposedSize() throws {
        let wrapped = try Self.capturedGeometry { probe in probe.measurePaywallWindowSize() }

        // The published window size is exactly the proposal the content receives: what the
        // content's own `GeometryReader` measures.
        expect(wrapped.publishedWindowSize) == wrapped.size
        expect(wrapped.size.width) > 0
        expect(wrapped.size.height) > 0
    }

    // MARK: - Harness

    private struct CapturedGeometry {
        var size: CGSize = .zero
        var insets = EdgeInsets()
        var publishedWindowSize: CGSize?
    }

    private final class GeometryBox {
        var captured = CapturedGeometry()
    }

    /// Mimics `LoadedPaywallsV2View`'s root: a `GeometryReader` that reads its own size and safe
    /// area insets, recording them together with the published `\.paywallWindowSize`.
    private struct GeometryProbe: View {
        let box: GeometryBox
        @Environment(\.paywallWindowSize) private var paywallWindowSize

        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { self.record(proxy) }
                    .onChangeOf(proxy.size) { _ in self.record(proxy) }
            }
        }

        private func record(_ proxy: GeometryProxy) {
            self.box.captured.size = proxy.size
            self.box.captured.insets = proxy.safeAreaInsets
            self.box.captured.publishedWindowSize = self.paywallWindowSize
        }
    }

    /// Hosts the probe (optionally transformed by `wrap`) in a window with simulated safe area
    /// insets and returns what the probe observed after layout.
    @MainActor
    private static func capturedGeometry(
        wrap: (GeometryProbe) -> some View
    ) throws -> CapturedGeometry {
        UIView.setAnimationsEnabled(false)

        let box = GeometryBox()
        let controller = UIHostingController(rootView: wrap(GeometryProbe(box: box)))
        controller.additionalSafeAreaInsets = Self.safeArea

        let window = UIWindow(frame: .init(origin: .zero, size: Self.windowSize))
        window.isHidden = false
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.frame = window.bounds
        window.setNeedsLayout()
        window.layoutIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        // `onAppear` lands on the main run loop rather than during `layoutIfNeeded`.
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline, box.captured.size == .zero {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }

        window.rootViewController = nil
        window.resignKey()
        window.isHidden = true

        expect(box.captured.size).toNot(
            equal(.zero),
            description: "Probe never laid out; the harness is broken."
        )
        return box.captured
    }

}

#endif
