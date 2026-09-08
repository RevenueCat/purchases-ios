//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SheetPresentationPlanTests.swift
//
//  Created by Facundo Menzella on 2026-09-07.

@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class SheetPresentationPlanTests: TestCase {

    // MARK: - First pass is hidden

    func testRequestedSheetIsHiddenUntilItHasSettled() {
        let plan = SheetPresentationPlan.make(requestedSheetID: "sheet-a", settledSheetID: nil)

        XCTAssertFalse(plan.isPresented)
    }

    func testRequestedSheetIsPresentedOnceItHasSettled() {
        let plan = SheetPresentationPlan.make(requestedSheetID: "sheet-a", settledSheetID: "sheet-a")

        XCTAssertTrue(plan.isPresented)
    }

    func testSwitchingToAnotherSheetHidesItUntilThatOneHasSettled() {
        let plan = SheetPresentationPlan.make(requestedSheetID: "sheet-b", settledSheetID: "sheet-a")

        XCTAssertFalse(plan.isPresented)
    }

    func testNothingRequestedIsNotPresented() {
        let plan = SheetPresentationPlan.make(requestedSheetID: nil, settledSheetID: "sheet-a")

        XCTAssertFalse(plan.isPresented)
    }

    // MARK: - Settled id bookkeeping

    func testDismissingClearsTheSettledSheet() {
        XCTAssertNil(SheetPresentationPlan.settledSheetID(afterRequesting: nil, previous: "sheet-a"))
    }

    func testRequestingADifferentSheetClearsTheSettledSheet() {
        XCTAssertNil(SheetPresentationPlan.settledSheetID(afterRequesting: "sheet-b", previous: "sheet-a"))
    }

    func testReRequestingTheSettledSheetKeepsItSettled() {
        XCTAssertEqual(
            SheetPresentationPlan.settledSheetID(afterRequesting: "sheet-a", previous: "sheet-a"),
            "sheet-a"
        )
    }

    func testRequestingASheetWithNothingSettledStaysUnsettled() {
        XCTAssertNil(SheetPresentationPlan.settledSheetID(afterRequesting: "sheet-a", previous: nil))
    }

    // MARK: - Reopening while dismissal is in flight

    func testReopeningTheMountedSheetReusesItsContent() {
        XCTAssertTrue(
            SheetPresentationPlan.reusesMountedContent(requestedSheetID: "sheet-a", mountedSheetID: "sheet-a")
        )
    }

    func testOpeningADifferentSheetDoesNotReuseTheMountedContent() {
        XCTAssertFalse(
            SheetPresentationPlan.reusesMountedContent(requestedSheetID: "sheet-b", mountedSheetID: "sheet-a")
        )
    }

    func testOpeningWithNothingMountedDoesNotReuseContent() {
        XCTAssertFalse(
            SheetPresentationPlan.reusesMountedContent(requestedSheetID: "sheet-a", mountedSheetID: nil)
        )
    }

    func testDismissingDoesNotReuseContent() {
        XCTAssertFalse(
            SheetPresentationPlan.reusesMountedContent(requestedSheetID: nil, mountedSheetID: "sheet-a")
        )
    }

    // MARK: - Sheet present from the start

    #if canImport(UIKit) && !os(watchOS)
    /// Previews (and their Emerge snapshots) create the overlay with the sheet already open and capture
    /// the very first frame. That frame must show the sheet: there is nothing for it to slide in from.
    @MainActor
    func testSheetPresentAtCreationRendersOnTheFirstFrame() throws {
        let image = try Self.renderFirstFrame(BottomSheetViewTestView(), size: CGSize(width: 390, height: 844))

        // The sheet's white background sits at the bottom; without it that band is the gray backdrop.
        let whitePixels = try Self.countWhitePixels(in: image, bottomRows: 40)

        XCTAssertGreaterThan(whitePixels, 390 * 40 / 4, "Sheet content should be visible on the first frame")
    }
    #endif

}

#if canImport(UIKit) && !os(watchOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension SheetPresentationPlanTests {

    /// Hosts the view and rasterizes it without spinning the run loop, so nothing scheduled with
    /// `DispatchQueue.main.async` has run yet, which is what a preview snapshot sees.
    @MainActor
    static func renderFirstFrame(_ view: some View, size: CGSize) throws -> UIImage {
        UIView.setAnimationsEnabled(false)

        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .white

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.isHidden = false
        window.backgroundColor = .white
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.frame = window.bounds
        window.setNeedsLayout()
        window.layoutIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        // `layer.render(in:)` rather than `drawHierarchy`: the latter yields a black image under XCTest.
        return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    static func countWhitePixels(in image: UIImage, bottomRows: Int) throws -> Int {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * 4 * height)
        let context = try XCTUnwrap(CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))

        var count = 0
        for row in max(0, height - bottomRows)..<height {
            for column in 0..<width {
                let offset = row * width * 4 + column * 4
                if buffer[offset] == 255, buffer[offset + 1] == 255, buffer[offset + 2] == 255 {
                    count += 1
                }
            }
        }
        return count
    }

}
#endif

#endif
