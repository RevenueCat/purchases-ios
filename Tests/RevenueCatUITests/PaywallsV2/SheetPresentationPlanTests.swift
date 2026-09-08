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

@_spi(Internal) import RevenueCat
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

    /// A relative sheet height is a fraction of the parent's height, which must follow the parent when the
    /// window is resized or rotated instead of sticking to the size seen on first appearance.
    @MainActor
    func testRelativeSheetHeightFollowsParentResize() throws {
        let portrait = CGSize(width: 390, height: 844)
        let landscape = CGSize(width: 844, height: 390)
        let host = try Self.makeHost(sheetHeight: .relative(0.5))

        let (window, render) = Self.hostForResizing(host, size: portrait)
        let before = try Self.countWhiteRows(in: render(), column: 5)

        Self.resize(window, to: landscape)
        let after = try Self.countWhiteRows(in: render(), column: 5)

        XCTAssertEqual(before, Int(portrait.height / 2), accuracy: 2)
        XCTAssertEqual(after, Int(landscape.height / 2), accuracy: 2,
                       "Sheet should be half of the new parent height, not of the original one")
    }

    /// The real path: the overlay starts with no sheet and a carousel sheet is requested later. The
    /// sheet's first 20pt are padding and the carousel follows, so as soon as more than that is on
    /// screen the carousel must already be there. Before the fix it was measured at 0 on the first
    /// pass and grew while the sheet slid in, so early frames showed only the white padding.
    @MainActor
    func testCarouselIsAtFullHeightAsSoonAsTheSheetShows() throws {
        let size = CGSize(width: 390, height: 844)
        let holder = SheetHolder()
        let (window, render) = Self.hostForResizing(LateSheetHost(holder: holder), size: size)

        holder.sheet = try Self.makeCarouselSheet(pageHeight: 200)
        // One layout pass, no run loop turn: nothing scheduled with `DispatchQueue.main.async` has run.
        window.layoutIfNeeded()
        XCTAssertEqual(try Self.countSheetRows(in: render()), 0, "Sheet must not show before its content settled")

        // Sample frames while the sheet comes in and grab the first one showing more than the top padding.
        var firstShowingFrame: UIImage?
        let deadline = Date().addingTimeInterval(2)
        while firstShowingFrame == nil, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.016))
            let frame = render()
            if try Self.countSheetRows(in: frame) >= 60 {
                firstShowingFrame = frame
            }
        }
        let frame = try XCTUnwrap(firstShowingFrame, "Sheet never showed")

        XCTAssertGreaterThan(try Self.countRedRows(in: frame), 0,
                             "Carousel must already have its height when the sheet first shows")

        RunLoop.main.run(until: Date().addingTimeInterval(1))
        XCTAssertEqual(try Self.countRedRows(in: render()), 200, accuracy: 2)
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

    static func makeHost(sheetHeight: PaywallComponent.SizeConstraint) throws -> some View {
        let text = PaywallComponent.text(
            PaywallComponent.TextComponent(text: "sheetText", color: .init(light: .hex("#000000")))
        )
        let stack = PaywallComponent.StackComponent(
            components: [text],
            size: .init(width: .fill, height: .fill),
            backgroundColor: .init(light: .hex("#FFFFFF"))
        )
        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: "resizeSheet",
            name: nil,
            stack: .init(components: [text], backgroundColor: nil),
            backgroundBlur: false,
            size: .init(width: .fill, height: sheetHeight)
        )
        let stackViewModel = try StackComponentViewModel(
            component: stack,
            localizationProvider: .init(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["sheetText": PaywallComponentsData.LocalizationData.string("Sheet")]
            ),
            colorScheme: .light
        )
        return ResizingSheetHost(sheet: SheetViewModel(sheet: sheet, sheetStackViewModel: stackViewModel))
    }

    /// A sheet whose only content is a carousel with one page of the given fixed height, painted red.
    static func makeCarouselSheet(pageHeight: Double) throws -> SheetViewModel {
        let page = PaywallComponent.StackComponent(
            components: [],
            size: PaywallComponent.Size(width: .fill, height: .fixed(UInt(pageHeight))),
            backgroundColor: PaywallComponent.ColorScheme(light: .hex("#FF0000"))
        )
        let carousel = PaywallComponent.CarouselComponent(pages: [page])
        let stack = PaywallComponent.StackComponent(
            components: [.carousel(carousel)],
            size: PaywallComponent.Size(width: .fill, height: .fit(nil)),
            backgroundColor: PaywallComponent.ColorScheme(light: .hex("#FFFFFF")),
            padding: PaywallComponent.Padding(top: 20, bottom: 20, leading: 0, trailing: 0)
        )
        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: "carouselSheet",
            name: nil,
            stack: stack,
            backgroundBlur: false,
            size: PaywallComponent.Size(width: .fill, height: .fit(nil))
        )
        let stackViewModel = try StackComponentViewModel(
            component: stack,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            colorScheme: .light
        )
        return SheetViewModel(sheet: sheet, sheetStackViewModel: stackViewModel)
    }

    /// Rows of the red carousel page, sampled at the horizontal center.
    static func countRedRows(in image: UIImage) throws -> Int {
        let pixels = try Self.rgbaBytes(of: image)
        let column = pixels.width / 2
        var count = 0
        for row in 0..<pixels.height {
            let offset = row * pixels.width * 4 + column * 4
            let isRed = pixels.bytes[offset] > 200 && pixels.bytes[offset + 1] < 80 && pixels.bytes[offset + 2] < 80
            if isRed { count += 1 }
        }
        return count
    }

    /// Rows of the sheet on screen: anything at the horizontal center that is not the blue backdrop.
    static func countSheetRows(in image: UIImage) throws -> Int {
        let pixels = try Self.rgbaBytes(of: image)
        let column = pixels.width / 2
        var count = 0
        for row in 0..<pixels.height {
            let offset = row * pixels.width * 4 + column * 4
            let isBlue = pixels.bytes[offset] < 60 && pixels.bytes[offset + 1] < 160 && pixels.bytes[offset + 2] > 200
            if !isBlue { count += 1 }
        }
        return count
    }

    /// Hosts the view in a window and returns it with a renderer, so the caller can resize and re-render.
    @MainActor
    static func hostForResizing(_ view: some View, size: CGSize) -> (UIWindow, () -> UIImage) {
        UIView.setAnimationsEnabled(false)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.isHidden = false
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.resize(window, to: size)

        let render: () -> UIImage = {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
                window.layer.render(in: context.cgContext)
            }
        }
        return (window, render)
    }

    @MainActor
    static func resize(_ window: UIWindow, to size: CGSize) {
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController?.view.frame = window.bounds
        window.setNeedsLayout()
        window.layoutIfNeeded()
        // SwiftUI applies state written from geometry callbacks on the next update, so give it one.
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        window.layoutIfNeeded()
    }

    /// Height of the sheet: contiguous white rows from the bottom edge at the given column.
    static func countWhiteRows(in image: UIImage, column: Int) throws -> Int {
        let pixels = try Self.rgbaBytes(of: image)
        var count = 0
        for row in stride(from: pixels.height - 1, through: 0, by: -1) {
            let offset = row * pixels.width * 4 + column * 4
            guard pixels.bytes[offset] == 255, pixels.bytes[offset + 1] == 255, pixels.bytes[offset + 2] == 255 else {
                break
            }
            count += 1
        }
        return count
    }

    static func rgbaBytes(of image: UIImage) throws -> (width: Int, height: Int, bytes: [UInt8]) {
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
        return (width, height, buffer)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class SheetHolder: ObservableObject {
    @Published var sheet: SheetViewModel?
}

/// Blue backdrop with no sheet at first; the test assigns one later, like a button tap would.
/// Animations are disabled so the presented state lands in a single frame.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct LateSheetHost: View {

    @ObservedObject var holder: SheetHolder

    var body: some View {
        Color.blue
            .bottomSheet(
                sheet: Binding(get: { self.holder.sheet }, set: { self.holder.sheet = $0 }),
                safeAreaInsets: EdgeInsets(),
                onSheetContentAppear: nil
            )
            .ignoresSafeArea()
            .transaction { $0.animation = nil }
            .previewRequiredPaywallsV2Properties()
    }

}

/// Blue backdrop with the sheet already open, so the sheet's white background can be measured.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ResizingSheetHost: View {

    @State var sheet: SheetViewModel?

    var body: some View {
        Color.blue
            .bottomSheet(sheet: self.$sheet, safeAreaInsets: EdgeInsets(), onSheetContentAppear: nil)
            .ignoresSafeArea()
            .previewRequiredPaywallsV2Properties()
    }

}
#endif

#endif
