//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FixedSizeOverflowUITests.swift

import XCTest

/// Measures what is actually drawn: a stack with a fixed size keeps it when `overflow` is `scroll`.
final class FixedSizeOverflowUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// The ring is the only green on screen. Its border and dot share the color, so the bounding
    /// box of every green pixel is the ring's outer size. Before the fix the scroll view wrapper
    /// took the row height and the box came out as tall as the row.
    func testFixedPillRingWithOverflowScrollStaysACircle() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "fixed_pill_overflow_scroll"
        app.launch()
        XCTAssertTrue(
            app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Monthly plan'"))
                .waitForExistence(timeout: 30),
            "Fixture did not render."
        )

        let screenshot = XCUIScreen.main.screenshot().image
        let ring = try XCTUnwrap(Self.boundingBoxOfGreenPixels(in: screenshot), "No ring found on screen.")
        let diagnostics = "ring=\(ring) image=\(screenshot.cgImage.map { "\($0.width)x\($0.height)" } ?? "?")"
            + " scale=\(screenshot.scale) screen=\(UIScreen.main.bounds.size)@\(UIScreen.main.scale)"

        // Same tolerance in both directions: 22pt ring plus a 2pt border on each side, in pixels.
        let expectedSide = 26 * screenshot.scale
        XCTAssertEqual(ring.width, expectedSide, accuracy: 2, "Ring width is off: \(diagnostics)")
        XCTAssertEqual(ring.height, expectedSide, accuracy: 2, "Ring is not a circle: \(diagnostics)")
    }

    /// Bounding box, in pixels, of every pixel close to the fixture's `#7CB518`.
    private static func boundingBoxOfGreenPixels(in image: UIImage) -> CGRect? {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let pixels = CFDataGetBytePtr(data) else {
            return nil
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let alphaFirst = cgImage.alphaInfo == .premultipliedFirst || cgImage.alphaInfo == .first
        let littleEndian = cgImage.bitmapInfo.contains(.byteOrder32Little)
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1

        for row in 0..<cgImage.height {
            for column in 0..<cgImage.width {
                let offset = row * cgImage.bytesPerRow + column * bytesPerPixel
                let red: UInt8, green: UInt8, blue: UInt8
                switch (littleEndian, alphaFirst) {
                case (true, true):   // BGRA in memory
                    blue = pixels[offset]; green = pixels[offset + 1]; red = pixels[offset + 2]
                case (true, false):  // ABGR
                    blue = pixels[offset + 1]; green = pixels[offset + 2]; red = pixels[offset + 3]
                case (false, true):  // ARGB
                    red = pixels[offset + 1]; green = pixels[offset + 2]; blue = pixels[offset + 3]
                case (false, false): // RGBA
                    red = pixels[offset]; green = pixels[offset + 1]; blue = pixels[offset + 2]
                }
                // #7CB518 is (124, 181, 24). Edges are antialiased against white, so accept a band.
                guard green > 140, red < 190, blue < 120, Int(green) - Int(red) > 30 else { continue }
                minX = min(minX, column)
                minY = min(minY, row)
                maxX = max(maxX, column)
                maxY = max(maxY, row)
            }
        }

        guard maxX >= 0 else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

}
