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

    func testFixedSizeIncludesContentInsets() {
        let contentInsets = EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        let view = Color.clear
            .size(
                .init(width: .fixed(50), height: .fixed(40)),
                subtracting: contentInsets
            )
            .padding(contentInsets)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 50, height: 40)
        )
    }

    func testMarginRemainsOutsideFixedSize() {
        let contentInsets = EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        let margin = EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 4)
        let view = Color.clear
            .size(
                .init(width: .fixed(50), height: .fixed(40)),
                subtracting: contentInsets
            )
            .padding(contentInsets)
            .padding(margin)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 58, height: 46)
        )
    }

    func testFixedMediaSizeIncludesContentInsets() {
        let contentInsets = EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        let size = PaywallComponent.Size(width: .fixed(50), height: .fixed(40))
        let view = Color.clear
            .applyMediaWidth(size: size, subtracting: contentInsets)
            .applyMediaHeight(size: size, aspectRatio: 1, subtracting: contentInsets)
            .padding(contentInsets)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 50, height: 40)
        )
    }

    func testFixedWidthMediaWithFitHeightUsesInsetContentWidth() {
        let contentInsets = EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        let size = PaywallComponent.Size(width: .fixed(50), height: .fit(nil))
        let view = Color.clear
            .applyMediaWidth(size: size, subtracting: contentInsets)
            .applyMediaHeight(size: size, aspectRatio: 2, subtracting: contentInsets)
            .padding(contentInsets)

        XCTAssertEqual(
            Self.fittingSize(of: view, in: .init(width: 100, height: 100)),
            .init(width: 50, height: 25)
        )
    }

    private static func fittingSize<Content: View>(of view: Content, in proposal: CGSize) -> CGSize {
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    }

}

#endif
