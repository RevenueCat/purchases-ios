//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackgroundStyleTests.swift
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, *)
@MainActor
final class BackgroundStyleTests: TestCase {

    /// A "fill" image taller than its view must not draw outside it, and clipping it must not
    /// render the content a second time.
    func testTallFillImageBackgroundIsClippedAndRendersContentOnce() throws {
        let url = try Self.redImageURL(size: CGSize(width: 10, height: 40))
        var appearCount = 0
        let view = Color.clear
            .frame(width: 100, height: 60)
            .onAppear { appearCount += 1 }
            .backgroundStyle(.image(
                .init(light: .init(width: 10, height: 40, original: url, heic: url, heicLowRes: url)),
                .fill,
                nil
            ))

        let window = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Unclipped, the image scales to 100x400 and fills the whole column.
        XCTAssertEqual(try Self.redRowCount(in: window), 60)
        XCTAssertEqual(appearCount, 1)
    }

    /// Clipping a video background must not render the content a second time.
    func testVideoBackgroundRendersContentOnce() throws {
        let viewModel = VideoComponentViewModel.forBackground(
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: .init(
                source: .init(light: .init(
                    width: 100,
                    height: 400,
                    url: try XCTUnwrap(URL(string: "https://assets.revenuecat.com/video.mp4")),
                    checksum: nil,
                    urlLowRes: nil,
                    checksumLowRes: nil
                )),
                fitMode: .fill
            )
        )
        var appearCount = 0
        let view = Color.clear
            .frame(width: 100, height: 60)
            .onAppear { appearCount += 1 }
            .backgroundStyle(.video(viewModel, nil))
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))

        let window = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertEqual(appearCount, 1)
    }

    private static func host<Content: View>(_ view: Content) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        window.backgroundColor = .white
        window.rootViewController = UIHostingController(rootView: view.frame(width: 300, height: 400))
        window.makeKeyAndVisible()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        return window
    }

    private static func redImageURL(size: CGSize) throws -> URL {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BackgroundStyleTests-red.png")
        try XCTUnwrap(image.pngData()).write(to: url)
        return url
    }

    /// Counts the rows that are red in the window's middle column.
    private static func redRowCount(in window: UIWindow) throws -> Int {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let screenshot = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        let image = try XCTUnwrap(screenshot.cgImage)
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (0..<height).filter { row in
            let index = (row * width + width / 2) * 4
            return pixels[index] > 200 && pixels[index + 1] < 50 && pixels[index + 2] < 50
        }.count
    }

}

#endif
