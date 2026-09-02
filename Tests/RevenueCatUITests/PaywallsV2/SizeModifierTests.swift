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
        XCTAssertFalse(PaywallComponent.SizeConstraint.fit(nil, .init(min: 20, max: 30)).isFill)
    }

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

    func testFitWithMinimumUsesFlexDistribution() {
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
                .flex
            )
        }
    }

    func testUnconstrainedFitDoesNotUseFlexDistribution() {
        XCTAssertEqual(
            StackComponentStyle.strategy(for: .spaceBetween, sizeConstraint: .fit(nil)),
            .normal
        )
        XCTAssertEqual(
            StackComponentStyle.strategy(
                for: .spaceBetween,
                sizeConstraint: .fit(nil, .init(min: nil, max: 100))
            ),
            .normal
        )
        XCTAssertEqual(
            StackComponentStyle.strategy(
                for: .spaceBetween,
                sizeConstraint: .fit(nil, .init(min: 0, max: nil))
            ),
            .normal
        )
    }

    private static func fittingSize<Content: View>(of view: Content, in proposal: CGSize) -> CGSize {
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    }

}

#endif
