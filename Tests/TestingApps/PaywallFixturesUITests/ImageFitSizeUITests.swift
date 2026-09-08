//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageFitSizeUITests.swift

import XCTest

/// Measures the drawn size of an image whose width and height are both Fit.
final class ImageFitSizeUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    /// Fit means the image's own pixel size read as points, the way the paywall editor previews
    /// it, so a 300x200 px image draws 300x200 pt whatever the stack around it offers.
    func testFitImageDrawsAtItsOwnSize() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "fit_image_in_equal_spacing_stack"
        app.launch()
        let rendered = app.staticTexts["Bottom button"].waitForExistence(timeout: 30)
        if !rendered {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/fit_image_debug.png"))
            let labels = app.staticTexts.allElementsBoundByIndex.prefix(12).map(\.label).joined(separator: " | ")
            XCTFail("Fixture did not render. On screen: \(labels)")
        }

        let screenshot = XCUIScreen.main.screenshot().image
        let image = try XCTUnwrap(Self.boundingBoxOfSaturatedPixels(in: screenshot), "No image found on screen.")
        let diagnostics = "image=\(image) screenshot=\(screenshot.cgImage.map { "\($0.width)x\($0.height)" } ?? "?")"

        let scale = screenshot.scale
        XCTAssertEqual(image.width, 300 * scale, accuracy: 3,
                       "Fit image is not drawn at its own width: \(diagnostics)")
        XCTAssertEqual(image.height, 200 * scale, accuracy: 3,
                       "Fit image is not drawn at its own height: \(diagnostics)")
    }

    /// Bounding box, in pixels, of every clearly colored pixel. Text is black and the page is
    /// white, so only the green fixture image is saturated.
    private static func boundingBoxOfSaturatedPixels(in image: UIImage) -> CGRect? {
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
                let channels: [UInt8]
                switch (littleEndian, alphaFirst) {
                case (true, true):   // BGRA in memory
                    channels = [pixels[offset + 2], pixels[offset + 1], pixels[offset]]
                case (true, false):  // ABGR
                    channels = [pixels[offset + 3], pixels[offset + 2], pixels[offset + 1]]
                case (false, true):  // ARGB
                    channels = [pixels[offset + 1], pixels[offset + 2], pixels[offset + 3]]
                case (false, false): // RGBA
                    channels = [pixels[offset], pixels[offset + 1], pixels[offset + 2]]
                }
                let saturation = Int(channels.max()!) - Int(channels.min()!)
                guard saturation > 80 else { continue }
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
