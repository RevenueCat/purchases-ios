//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageComponentViewTests.swift
//
//  Created by RevenueCat.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ImageComponentViewTests: TestCase {

    // MARK: - Render/measurement flow (what #6593 set out to solve)

    // While our size is unknown we must render a greedy, content-free placeholder so the parent's
    // available width can be measured before the image is constrained. This is the behavior the
    // "Fix image size/render flow" change introduced so that fill/fixed-width images don't push
    // past their bounds, and it must be preserved.
    func testMeasurementPlaceholderIsShownWhileSizeIsUnknown() {
        let plan = ImageComponentView.renderPlan(
            sizeIsKnown: false,
            requestSizeCalculation: false,
            isRenderingForPreview: false
        )

        XCTAssertTrue(plan.showsMeasurementPlaceholder)
    }

    // Once the size is known and no recalculation was requested, the image is rendered directly
    // with no measurement placeholder.
    func testImageRenderedDirectlyWhenSizeIsKnown() {
        let plan = ImageComponentView.renderPlan(
            sizeIsKnown: true,
            requestSizeCalculation: false,
            isRenderingForPreview: false
        )

        XCTAssertFalse(plan.showsMeasurementPlaceholder)
        XCTAssertEqual(plan.content, .image)
    }

    // Far-offscreen carousel pages set `requestSizeCalculation` so they can be measured without
    // eagerly loading their image. Even though the size may already be known, we must NOT mount
    // the image for these pages — doing so would regress the carousel's lazy-loading optimization.
    func testOffscreenCarouselPageMeasuresWithoutLoadingImage() {
        let plan = ImageComponentView.renderPlan(
            sizeIsKnown: true,
            requestSizeCalculation: true,
            isRenderingForPreview: false
        )

        XCTAssertTrue(plan.showsMeasurementPlaceholder)
        XCTAssertEqual(plan.content, .none)
    }

    // Regression guard for the carousel lazy-load path: a far-offscreen page that has not been
    // measured yet (size unknown) AND has requestSizeCalculation set must NOT mount the image. The
    // lazy-load skip must win over the first-load mount, otherwise we start fetching images for
    // pages the user may never reach.
    func testOffscreenCarouselPageDoesNotMountImageBeforeFirstMeasurement() {
        let plan = ImageComponentView.renderPlan(
            sizeIsKnown: false,
            requestSizeCalculation: true,
            isRenderingForPreview: false
        )

        XCTAssertTrue(plan.showsMeasurementPlaceholder)
        XCTAssertEqual(plan.content, .none)
    }

    // MARK: - First-load animation regression

    // Regression guard for the paywall sheet bug: on the first (uncached) load the size is not yet
    // known, so the view forces a size calculation. The image must STILL be mounted in the
    // hierarchy alongside the measurement placeholder, otherwise it is only inserted after the size
    // resolves — by which point the enclosing sheet transition has already started, and the image
    // appears anchored at its final position instead of animating in with the sheet.
    func testImageIsMountedOnFirstLoadWhileSizeIsUnknown() {
        let plan = ImageComponentView.renderPlan(
            sizeIsKnown: false,
            requestSizeCalculation: false,
            isRenderingForPreview: false
        )

        XCTAssertEqual(
            plan.content,
            .image,
            "The image must be mounted on first load so it participates in the enclosing transition"
        )
        // It is still measured at the same time, so fill/fixed-width images stay within bounds.
        XCTAssertTrue(plan.showsMeasurementPlaceholder)
    }

    // MARK: - Size-change acceptance (carousel shared-cache race)

    // Regression for looping carousels: multiple page copies share one ImageComponentViewModel
    // (and thus one cachedMeasuredSize). When local @State is still nil, a measurement must be
    // accepted even if it equals the shared cache — otherwise the visible copy stays stuck in
    // the "size unknown" path (image mounted with maxWidth: 0).
    func testAcceptsMeasurementWhenLocalSizeIsNilEvenIfMatchingSharedCache() {
        let measured = CGSize(width: 320, height: 200)

        XCTAssertTrue(
            ImageComponentView.shouldAcceptMeasuredSize(localSize: nil, newSize: measured),
            "A nil local size must accept the measurement regardless of any shared cached size"
        )
    }

    // Once local state already holds this size, reject identical re-measurements to avoid
    // redraw churn. Init seeds _size from cachedMeasuredSize, so remounted views still short-circuit.
    func testRejectsMeasurementWhenLocalSizeAlreadyMatches() {
        let measured = CGSize(width: 320, height: 200)

        XCTAssertFalse(
            ImageComponentView.shouldAcceptMeasuredSize(localSize: measured, newSize: measured)
        )
    }

    func testAcceptsMeasurementWhenLocalSizeDiffers() {
        let previous = CGSize(width: 100, height: 50)
        let measured = CGSize(width: 320, height: 200)

        XCTAssertTrue(
            ImageComponentView.shouldAcceptMeasuredSize(localSize: previous, newSize: measured)
        )
    }

    // MARK: - maxWidth sizing math (keeps the image within the parent's bounds)

    func testCalculateMaxWidthSubtractsBordersPaddingAndMargin() {
        let style = Self.makeStyle(
            borderWidth: 4,
            padding: .init(top: 0, bottom: 0, leading: 20, trailing: 20),
            margin: .init(top: 0, bottom: 0, leading: 10, trailing: 10)
        )

        // 400 - (4 * 2) border - (10 + 10) margin - (20 + 20) padding
        XCTAssertEqual(ImageComponentView.calculateMaxWidth(parentWidth: 400, style: style), 332)
    }

    func testCalculateMaxWidthEqualsParentWidthWithoutInsets() {
        let style = Self.makeStyle(borderWidth: nil, padding: .zero, margin: .zero)

        XCTAssertEqual(ImageComponentView.calculateMaxWidth(parentWidth: 320, style: style), 320)
    }

    func testCalculateMaxWidthNeverGoesNegative() {
        let style = Self.makeStyle(
            borderWidth: 4,
            padding: .init(top: 0, bottom: 0, leading: 40, trailing: 40),
            margin: .init(top: 0, bottom: 0, leading: 40, trailing: 40)
        )

        XCTAssertEqual(ImageComponentView.calculateMaxWidth(parentWidth: 10, style: style), 0)
    }

    // MARK: - Helpers

    private static func makeStyle(
        borderWidth: Double?,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding
    ) -> ImageComponentStyle {
        let url = URL(string: "https://assets.pawwalls.com/test.heic")!
        return ImageComponentStyle(
            source: .init(
                light: .init(width: 750, height: 530, original: url, heic: url, heicLowRes: url)
            ),
            size: .init(width: .fill, height: .fit(nil)),
            fitMode: .fit,
            padding: padding,
            margin: margin,
            border: borderWidth.map { .init(color: .init(light: .hex("#ff0000")), width: $0) },
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        )
    }

}

#endif
