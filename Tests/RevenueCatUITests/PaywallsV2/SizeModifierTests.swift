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

    func testFitWithPositiveMinimumUsesFlexDistribution() {
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

    func testFitMinimumDistributesOnlyRemainingSpace() {
        XCTAssertEqual(
            FlexSpacer.lengthPerWeight(
                fitMinimum: 100,
                contentLength: 40,
                spacing: 10,
                componentCount: 2,
                totalWeight: 1
            ),
            50
        )
        XCTAssertEqual(
            FlexSpacer.lengthPerWeight(
                fitMinimum: 100,
                contentLength: 40,
                spacing: 10,
                componentCount: 2,
                totalWeight: 4
            ),
            12.5
        )
        XCTAssertEqual(
            FlexSpacer.lengthPerWeight(
                fitMinimum: 30,
                contentLength: 40,
                spacing: 0,
                componentCount: 2,
                totalWeight: 1
            ),
            0
        )
    }

    func testFitWithMinimumDoesNotExpandVerticalStackToParentProposal() {
        let height = PaywallComponent.SizeConstraint.fit(nil, .init(min: 100, max: nil))
        let view = Self.verticalStack(distribution: .spaceBetween, height: height)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 500)).height,
            100
        )
    }

    func testFitWithMinimumDoesNotExpandHorizontalStackToParentProposal() {
        let width = PaywallComponent.SizeConstraint.fit(nil, .init(min: 100, max: nil))
        let view = Self.horizontalStack(distribution: .spaceBetween, width: width)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 500, height: 100)).width,
            100
        )
    }

    func testFitWithMinimumCanStillGrowToContentSize() {
        let constraint = PaywallComponent.SizeConstraint.fit(nil, .init(min: 30, max: nil))

        XCTAssertEqual(
            Self.fittingSize(
                of: Self.verticalStack(distribution: .spaceBetween, height: constraint),
                in: .init(width: 100, height: 500)
            ).height,
            40
        )
        XCTAssertEqual(
            Self.fittingSize(
                of: Self.horizontalStack(distribution: .spaceBetween, width: constraint),
                in: .init(width: 500, height: 100)
            ).width,
            40
        )
    }

    @ViewBuilder
    private static func verticalStack(
        distribution: PaywallComponent.FlexDistribution,
        height: PaywallComponent.SizeConstraint
    ) -> some View {
        let row = Color.clear.frame(width: 10, height: 20)

        switch StackComponentStyle.strategy(for: distribution, sizeConstraint: height) {
        case .normal:
            VStack(spacing: 0) {
                row
                row
            }
            .size(.init(width: .fit(nil), height: height))
        case .flex:
            VStack(spacing: 0) {
                row
                if let spacerLength = FlexSpacer.lengthPerWeight(
                    fitMinimum: Self.fitMinimum(height),
                    contentLength: 40,
                    spacing: 0,
                    componentCount: 2,
                    totalWeight: 1
                ) {
                    Spacer(minLength: 0).frame(height: spacerLength)
                } else {
                    Spacer(minLength: 0)
                }
                row
            }
            .size(.init(width: .fit(nil), height: height))
        }
    }

    @ViewBuilder
    private static func horizontalStack(
        distribution: PaywallComponent.FlexDistribution,
        width: PaywallComponent.SizeConstraint
    ) -> some View {
        let column = Color.clear.frame(width: 20, height: 10)

        switch StackComponentStyle.strategy(for: distribution, sizeConstraint: width) {
        case .normal:
            HStack(spacing: 0) {
                column
                column
            }
            .size(.init(width: width, height: .fit(nil)))
        case .flex:
            HStack(spacing: 0) {
                column
                if let spacerLength = FlexSpacer.lengthPerWeight(
                    fitMinimum: Self.fitMinimum(width),
                    contentLength: 40,
                    spacing: 0,
                    componentCount: 2,
                    totalWeight: 1
                ) {
                    Spacer(minLength: 0).frame(width: spacerLength)
                } else {
                    Spacer(minLength: 0)
                }
                column
            }
            .size(.init(width: width, height: .fit(nil)))
        }
    }

    private static func fitMinimum(_ sizeConstraint: PaywallComponent.SizeConstraint) -> CGFloat? {
        guard case let .fit(_, minMax) = sizeConstraint else {
            return nil
        }

        return minMax.min.map(CGFloat.init)
    }

    private static func fittingSize<Content: View>(of view: Content, in proposal: CGSize) -> CGSize {
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    }

}

#endif
