//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentFixedSizeOverflowTests.swift

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// A stack with a fixed size along its scroll axis must keep that size when `overflow` is `scroll`.
@available(iOS 15.0, *)
@MainActor
final class StackComponentFixedSizeOverflowTests: TestCase {

    private static let proposal = CGSize(width: 300, height: 300)

    func testVerticalFixedStackWithoutOverflowFitsItsSize() throws {
        let view = try Self.makeStack(dimension: .vertical(.center, .center), overflow: nil)
        XCTAssertEqual(Self.fittingSize(of: view), Self.expectedOuterSize)
    }

    func testVerticalFixedStackWithOverflowScrollKeepsItsHeight() throws {
        let view = try Self.makeStack(dimension: .vertical(.center, .center), overflow: .scroll)
        XCTAssertEqual(Self.fittingSize(of: view), Self.expectedOuterSize)
    }

    func testHorizontalFixedStackWithOverflowScrollKeepsItsWidth() throws {
        let view = try Self.makeStack(dimension: .horizontal(.center, .center), overflow: .scroll)
        XCTAssertEqual(Self.fittingSize(of: view), Self.expectedOuterSize)
    }

    func testZLayerFixedStackWithOverflowScrollKeepsItsHeight() throws {
        let view = try Self.makeStack(dimension: .zlayer(.center), overflow: .scroll)
        XCTAssertEqual(Self.fittingSize(of: view), Self.expectedOuterSize)
    }

    func testFixedPillStackWithOverflowScrollRendersAsCircleInsideRow() throws {
        let row = PaywallComponent.StackComponent(
            components: [
                .stack(Self.ring(dimension: .vertical(.center, .center), overflow: .scroll)),
                // White on white so only the ring inks the canvas.
                .text(.init(text: "label", color: .init(light: .hex("#FFFFFF"))))
            ],
            dimension: .horizontal(.center, .start),
            size: .init(width: .fill, height: .fit(nil)),
            spacing: 8,
            padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12)
        )
        let view = try Self.makeView(row)

        let bounds = try Self.renderedInkBounds(of: view, canvas: Self.proposal)

        XCTAssertEqual(bounds.size, Self.expectedOuterSize, "ring should be a circle, got \(bounds)")
    }

    // MARK: - Fixtures

    private static let ringColor = "#7CB518"
    private static let fixedSide: UInt = 22
    private static let borderWidth: Double = 2
    /// iOS lays the border outside the fixed frame.
    private static let expectedOuterSize = CGSize(width: Double(fixedSide) + 2 * borderWidth,
                                                  height: Double(fixedSide) + 2 * borderWidth)

    private static func ring(
        dimension: PaywallComponent.Dimension,
        overflow: PaywallComponent.StackComponent.Overflow?
    ) -> PaywallComponent.StackComponent {
        .init(
            components: [
                .stack(.init(
                    components: [],
                    size: .init(width: .fixed(10), height: .fixed(10)),
                    backgroundColor: .init(light: .hex(ringColor)),
                    shape: .pill
                ))
            ],
            dimension: dimension,
            size: .init(width: .fixed(fixedSide), height: .fixed(fixedSide)),
            shape: .pill,
            border: .init(color: .init(light: .hex(ringColor)), width: borderWidth),
            overflow: overflow
        )
    }

    private static func makeStack(
        dimension: PaywallComponent.Dimension,
        overflow: PaywallComponent.StackComponent.Overflow?
    ) throws -> some View {
        try makeView(ring(dimension: dimension, overflow: overflow))
    }

    private static func makeView(_ component: PaywallComponent.StackComponent) throws -> some View {
        StackComponentView(
            viewModel: try .init(
                component: component,
                localizationProvider: .init(locale: .current, localizedStrings: ["label": .string("Monthly")]),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
    }

    // MARK: - Measurement

    private static func fittingSize<Content: View>(of view: Content) -> CGSize {
        UIHostingController(rootView: view).sizeThatFits(in: proposal)
    }

    /// Rasterizes the view at 1x and returns the bounding box of every non-white pixel.
    private static func renderedInkBounds<Content: View>(of view: Content, canvas: CGSize) throws -> CGRect {
        let controller = UIHostingController(rootView: view.background(Color.white))
        controller.view.backgroundColor = .white
        let window = UIWindow(frame: CGRect(origin: .zero, size: canvas))
        window.rootViewController = controller
        window.isHidden = false
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let pixels = CFDataGetBytePtr(data) else {
            throw XCTSkip("No pixel data")
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
        for row in 0..<cgImage.height {
            for column in 0..<cgImage.width {
                let offset = row * cgImage.bytesPerRow + column * bytesPerPixel
                let brightness = Int(pixels[offset]) + Int(pixels[offset + 1]) + Int(pixels[offset + 2])
                if brightness < 3 * 235 {
                    minX = min(minX, column)
                    minY = min(minY, row)
                    maxX = max(maxX, column)
                    maxY = max(maxY, row)
                }
            }
        }
        guard maxX >= 0 else { throw XCTSkip("Rendered image is blank") }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

}

#endif
