//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SizeModifierTests.swift

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, *)
@MainActor
final class SizeModifierTests: TestCase {

    func testConstrainedFillIsStillClassifiedAsFill() {
        XCTAssertTrue(PaywallComponent.SizeConstraint.fill(.init(min: 20, max: 30)).isFill)
        XCTAssertFalse(PaywallComponent.SizeConstraint.fit(nil).isFill)
    }

    func testFitHugsContent() {
        let view = Color.clear
            .frame(width: 10, height: 10)
            .size(.init(width: .fit(nil), height: .fit(nil)))

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 10, height: 10)
        )
    }

    func testFillTakesProposedSize() {
        let view = Color.clear
            .frame(width: 10, height: 10)
            .size(.init(width: .fill, height: .fill))

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 100, height: 100)
        )
    }

    func testFillDoesNotGrowToOversizedChild() {
        // Flexbox parity: an oversized child overflows its Fill parent instead of widening it.
        let view = Color.clear
            .frame(width: 500, height: 500)
            .size(.init(width: .fill, height: .fill))

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 100, height: 100)
        )
    }

    func testFillParentDoesNotGrowToChildMinimum() {
        // The constrained child reports its own minimum, but that minimum must not propagate upward.
        let child = Color.clear
            .size(.init(width: .fill(.init(min: 120, max: nil)), height: .fixed(10)))
        let parent = child
            .size(.init(width: .fill, height: .fixed(10)))

        XCTAssertEqual(Self.fittingSize(of: child, in: .init(width: 100, height: 100)).width, 120)
        XCTAssertEqual(Self.fittingSize(of: parent, in: .init(width: 100, height: 100)).width, 100)
    }

    func testFillRespectsMinimumHeight() {
        let view = Color.clear
            .size(
                .init(
                    width: .fixed(10),
                    height: .fill(.init(min: 30, max: nil))
                )
            )

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 20)).height, 30)
    }

    func testFillRespectsMaximumWidth() {
        let view = Color.clear
            .size(
                .init(
                    width: .fill(.init(min: nil, max: 20)),
                    height: .fixed(10)
                )
            )

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 100)).width, 20)
    }

    func testFillMinimumCanExceedParentWidth() {
        let view = Color.clear
            .size(
                .init(
                    width: .fill(.init(min: 120, max: nil)),
                    height: .fixed(10)
                )
            )

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 100)).width, 120)
    }

    func testMinimumTakesPrecedenceOverMaximum() {
        let view = Color.clear
            .size(
                .init(
                    width: .fill(.init(min: 40, max: 20)),
                    height: .fixed(10)
                )
            )

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 100)).width, 40)
    }

    func testShortScrollingFitHeightHugsContent() throws {
        try Self.requireFitScrollAvailability()
        let view = Color.clear.frame(width: 100, height: 100)
            .scrollableIfNecessaryWhenAvailable(.vertical, size: .fit(nil), alignment: .center)

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 600)),
                       .init(width: 100, height: 100))
    }

    func testScrollingFitHeightPreservesWrappedTextSize() throws {
        try Self.requireFitScrollAvailability()
        let content = Text("Unlock everything with a subscription. This offer wraps across several lines.")
            .font(.system(size: 30))
            .frame(width: 120)
        let proposal = CGSize(width: 120, height: 1000)
        let naturalSize = Self.fittingSize(of: content, in: proposal)
        let scrollingSize = Self.fittingSize(
            of: content.scrollableIfNecessaryWhenAvailable(.vertical, size: .fit(nil), alignment: .center),
            in: proposal
        )

        XCTAssertGreaterThan(naturalSize.height, 30)
        XCTAssertLessThan(naturalSize.height, proposal.height)
        XCTAssertEqual(scrollingSize, naturalSize)
    }

    func testTallScrollingFitHeightUsesBoundedViewport() throws {
        try Self.requireFitScrollAvailability()
        let view = Color.clear.frame(width: 100, height: 1000)
            .scrollableIfNecessaryWhenAvailable(.vertical, size: .fit(nil), alignment: .center)

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 600)),
                       .init(width: 100, height: 600))
    }

    func testShortScrollingFitWidthHugsContent() throws {
        try Self.requireFitScrollAvailability()
        let view = Color.clear.frame(width: 100, height: 100)
            .scrollableIfNecessaryWhenAvailable(.horizontal, size: .fit(nil), alignment: .center)

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 600, height: 100)),
                       .init(width: 100, height: 100))
    }

    func testWideScrollingFitWidthUsesBoundedViewport() throws {
        try Self.requireFitScrollAvailability()
        let view = Color.clear.frame(width: 1000, height: 100)
            .scrollableIfNecessaryWhenAvailable(.horizontal, size: .fit(nil), alignment: .center)

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 600, height: 100)),
                       .init(width: 600, height: 100))
    }

    func testScrollingFixedHeightKeepsExistingViewport() throws {
        try Self.requireFitScrollAvailability()
        let view = Color.clear.frame(width: 100, height: 100)
            .scrollableIfNecessaryWhenAvailable(.vertical, size: .fixed(100), alignment: .center)

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 600)),
                       .init(width: 100, height: 600))
    }

    private static func requireFitScrollAvailability() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("FIT scrolling uses ViewThatFits on iOS 16 and later")
        }
    }

    private static func fittingSize<Content: View>(of view: Content, in proposal: CGSize) -> CGSize {
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    }

}

#endif
