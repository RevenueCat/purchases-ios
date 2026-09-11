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

import Nimble
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
        XCTAssertFalse(PaywallComponent.SizeConstraint.fit(nil, .init(min: 20, max: 30)).isFill)
    }

    // MARK: - Fit

    func testFitContentRespectsMinimumWidthAndHeight() {
        let view = Color.clear
            .frame(width: 10, height: 10)
            .size(
                .init(
                    width: .fit(nil, .init(min: 20, max: nil)),
                    height: .fit(nil, .init(min: 30, max: nil))
                )
            )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 20, height: 30)
        )
    }

    func testEmptyFitContentUsesMinimumInsteadOfMaximum() {
        let view = VStack {}
            .size(
                .init(
                    width: .fit(nil, .init(min: 64, max: 96)),
                    height: .fit(nil, .init(min: 88, max: 110))
                )
            )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 500, height: 500)),
            .init(width: 64, height: 88)
        )
    }

    func testFitContentGrowsBetweenMinimumAndMaximum() {
        let view = Color.clear
            .frame(width: 75, height: 100)
            .size(
                .init(
                    width: .fit(nil, .init(min: 64, max: 96)),
                    height: .fit(nil, .init(min: 88, max: 110))
                )
            )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 500, height: 500)),
            .init(width: 75, height: 100)
        )
    }

    func testFitContentLargerThanMaximumDoesNotGrowTheBox() {
        let view = Color.clear
            .frame(width: 160, height: 160)
            .size(
                .init(
                    width: .fit(nil, .init(min: nil, max: 120)),
                    height: .fit(nil, .init(min: nil, max: 100))
                )
            )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 500, height: 500)),
            .init(width: 120, height: 100)
        )
    }

    func testFlexibleFitHeightUsesMinimumInsteadOfMaximum() {
        let view = Color.clear
            .frame(maxHeight: .infinity)
            .size(
                .init(
                    width: .fixed(100),
                    height: .fit(nil, .init(min: 60, max: 120))
                )
            )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 500)).height,
            60
        )
    }

    func testFlexibleFitWidthUsesMinimumInsteadOfMaximum() {
        let view = Color.clear
            .frame(maxWidth: .infinity)
            .size(
                .init(
                    width: .fit(nil, .init(min: 60, max: 120)),
                    height: .fixed(10)
                )
            )

        let width = Self.fittingSize(of: view, in: .init(width: 500, height: 100)).width
        XCTAssertEqual(width, 60)
    }

    func testLegacyFitFallbackUsesMinimumForEmptyContent() {
        let view = VStack {}
            .applyFitWidthLimits(.init(min: 64, max: 96), alignment: .center)
            .applyFitHeightLimits(.init(min: 88, max: 110), alignment: .center)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 500, height: 500)),
            .init(width: 64, height: 88)
        )
    }

    func testLegacyFitFallbackGrowsToIntrinsicContent() {
        let view = Color.clear
            .frame(width: 75, height: 100)
            .applyFitWidthLimits(.init(min: 64, max: 96), alignment: .center)
            .applyFitHeightLimits(.init(min: 88, max: 110), alignment: .center)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 500, height: 500)),
            .init(width: 75, height: 100)
        )
    }

    func testLegacyFitFallbackUsesMinimumForFlexibleHeight() {
        let view = Color.clear
            .frame(maxHeight: .infinity)
            .applyFitHeightLimits(.init(min: 60, max: 120), alignment: .center)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 500)).height,
            60
        )
    }

    func testFitMaximumWidthWrapsText() {
        let text = Text("A long label that has to wrap onto several lines to fit the maximum width")
            .font(.system(size: 14))
        let singleLineHeight = Self.fittingSize(of: text, in: .init(width: 1000, height: 500)).height

        let view = text
            .size(
                .init(
                    width: .fit(nil, .init(min: nil, max: 96)),
                    height: .fit(nil)
                )
            )
        let size = Self.fittingSize(of: view, in: .init(width: 500, height: 500))

        // Fit reports the wrapped content width, which can land just under the maximum.
        XCTAssertLessThanOrEqual(size.width, 96)
        XCTAssertGreaterThan(size.width, 48)
        XCTAssertGreaterThan(size.height, singleLineHeight * 2)
    }

    func testFitLimitsOnBothAxesMeasureWrappedHeight() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Only `FitSizeLayout` re-proposes the clamped size")
        }

        let text = Text("A long label that has to wrap onto several lines to fit the maximum width")
            .font(.system(size: 14))
        let singleLineHeight = Self.fittingSize(of: text, in: .init(width: 1000, height: 500)).height

        // The height limits must clamp the wrapped height, not the single-line height measured before the
        // width was clamped; otherwise the text is truncated to a single line.
        let view = text
            .size(
                .init(
                    width: .fit(nil, .init(min: nil, max: 96)),
                    height: .fit(nil, .init(min: 20, max: 200))
                )
            )
        let size = Self.fittingSize(of: view, in: .init(width: 500, height: 500))

        XCTAssertLessThanOrEqual(size.width, 96)
        XCTAssertGreaterThan(size.height, singleLineHeight * 2)
    }

    func testFitMinimumDoesNotShrinkContentLargerThanTheProposal() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Only `FitSizeLayout` re-proposes the clamped size")
        }

        // 450pt of rigid content in a 400pt parent: the inactive minimum must not clamp the box to the
        // proposal, which would make the content overflow its own background.
        let view = VStack(spacing: 0) {
            Color.clear.frame(width: 200, height: 150)
            Color.clear.frame(width: 200, height: 150)
            Color.clear.frame(width: 200, height: 150)
        }
        .size(
            .init(
                width: .fixed(200),
                height: .fit(nil, .init(min: 100, max: nil))
            )
        )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 400, height: 400)),
            .init(width: 200, height: 450)
        )
    }

    func testFitMinimumIsProposedToFillContent() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Only `FitSizeLayout` proposes the minimum back to the content")
        }

        let measured = MeasuredSize()
        let view = Color.clear
            .frame(maxHeight: .infinity)
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear { measured.size = proxy.size }
                    .onChangeOf(proxy.size) { measured.size = $0 }
            })
            .size(
                .init(
                    width: .fixed(100),
                    height: .fit(nil, .init(min: 120, max: 160))
                )
            )

        let dispose = try view.addToHierarchy()
        defer { dispose() }

        expect(measured.size).toEventually(equal(CGSize(width: 100, height: 120)))
    }

    // MARK: - Fill

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

    // MARK: - Sheet

    func testSheetFitRespectsMinimumHeight() {
        let view = Color.clear
            .frame(height: 10)
            .applySheetHeight(
                .fit(nil, .init(min: 40, max: nil)),
                parentHeight: 100
            )

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 100)).height, 40)
    }

    func testSheetFillRespectsMaximumHeight() {
        let view = Color.clear
            .applySheetHeight(
                .fill(.init(min: nil, max: 40)),
                parentHeight: 100
            )

        XCTAssertEqual(Self.fittingSize(of: view, in: .init(width: 100, height: 100)).height, 40)
    }

    #if ENABLE_PAYWALL_MIN_MAX_SIZING
    func testSheetSizeAppliesWidthAndHeightConstraints() {
        let view = Color.clear
            .applySheetSize(
                .init(
                    width: .fill(.init(min: nil, max: 40)),
                    height: .fixed(30)
                ),
                parentHeight: 100
            )

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 40, height: 30)
        )
    }
    #endif

    // MARK: - Stack strategy

    func testFitWithPositiveMinimumUsesFlexDistributionWhenLayoutIsAvailable() {
        let expected: StackComponentStyle.StackStrategy
        if #available(iOS 16.0, *) {
            expected = .flex
        } else {
            expected = .normal
        }

        for distribution in [
            PaywallComponent.FlexDistribution.spaceBetween,
            .spaceAround,
            .spaceEvenly
        ] {
            XCTAssertEqual(
                StackComponentStyle.strategy(
                    for: distribution,
                    sizeConstraint: .fit(nil, .init(min: 100, max: nil))
                ),
                expected
            )
        }
    }

    func testFitWithoutPositiveMinimumDoesNotUseFlexDistribution() {
        for sizeConstraint in [
            PaywallComponent.SizeConstraint.fit(nil),
            .fit(nil, .init(min: 0, max: nil)),
            .fit(nil, .init(min: nil, max: 100))
        ] {
            XCTAssertEqual(
                StackComponentStyle.strategy(for: .spaceBetween, sizeConstraint: sizeConstraint),
                .normal
            )
        }
    }

    // MARK: -

    private static func fittingSize<Content: View>(of view: Content, in proposal: CGSize) -> CGSize {
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    }

}

private final class MeasuredSize {
    var size: CGSize?
}

#endif
