//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultPaywallPreviews.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

#if DEBUG

#if canImport(AppKit)
import AppKit
#endif
import CoreGraphics
import RevenueCat
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallPreviews: PreviewProvider {

    static let offering = Offering(
        identifier: "one",
        serverDescription: "Offering 1",
        availablePackages: [
            .init(
                identifier: "one",
                packageType: .annual,
                storeProduct: PurchaseInformationFixtures
                    .product(id: "one", title: "Annual", duration: .year, price: 99.99),
                offeringIdentifier: "org one",
                webCheckoutUrl: nil
            ),
            .init(
                identifier: "two",
                packageType: .monthly,
                storeProduct: PurchaseInformationFixtures
                    .product(id: "two", title: "Monthly", duration: .month, price: 8.99),
                offeringIdentifier: "org one",
                webCheckoutUrl: nil
            )
        ],
        webCheckoutUrl: nil
    )

    static var previews: some View {
        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .previewDisplayName("Fallback Paywall R/G")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Fallback Paywall R/G Dark")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.blueGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .previewDisplayName("Fallback Paywall B/G")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.blueGreen.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Fallback Paywall B/G Dark")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.white)
        .previewDisplayName("Fallback Paywall P/O")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Fallback Paywall P/O Dark")

        DefaultPaywallView(
            handler: .mock(),
            warning: .missingLocalization,
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - localization")

        DefaultPaywallView(
            handler: .mock(),
            warning: .missingLocalization,
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - localization Dark")

        DefaultPaywallView(
            handler: .mock(),
            warning: .noPaywall("WAT"),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - no paywall")

        DefaultPaywallView(
            handler: .mock(),
            warning: .noPaywall("WAT"),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - no paywall Dark")
    }

    enum DualColorImageGenerator {

        // swiftlint:disable force_unwrapping
        static let redGreen = create(color1: .red, color2: .green)!
        static let blueGreen = create(color1: .blue, color2: .green)!
        static let purpleOrange = create(color1: .purple, color2: .orange)!

        /// Generates a CGImage split equally between two colors.
        /// - Parameters:
        ///   - color1: The first color (Left or Top).
        ///   - color2: The second color (Right or Bottom).
        ///   - size: The size of the resulting image in points.
        /// - Returns: A CGImage if creation is successful.
        static func createCGImage(
            color1: CGColor,
            color2: CGColor,
            size: CGSize = .init(width: 50, height: 50)
        ) -> CGImage? {
            guard size.width > 0, size.height > 0 else { return nil }

            let width = Int(size.width)
            let height = Int(size.height)

            let colorSpace = CGColorSpaceCreateDeviceRGB()

            // Create the bitmap context. We use premultipliedLast for standard ARGB/RGBA handling
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
            }

            let firstRect: CGRect
            let secondRect: CGRect

            let splitWidth = CGFloat(width) / 2.0
            firstRect = CGRect(x: 0, y: 0, width: splitWidth, height: CGFloat(height))
            secondRect = CGRect(x: splitWidth, y: 0, width: splitWidth, height: CGFloat(height))

            context.setFillColor(color1)
            context.fill(firstRect)

            context.setFillColor(color2)
            context.fill(secondRect)

            return context.makeImage()
        }

        /// Generates a SwiftUI Image and the underlying CGImage.
        /// - Returns: A PreviewAppIcon struct containing the SwiftUI Image and the source CGImage.
        static func create(
            color1: Color,
            color2: Color,
            size: CGSize = .init(width: 200, height: 200)
        ) -> PreviewAppIcon? {

            let cgColor1 = platformColor(from: color1).cgColor
            let cgColor2 = platformColor(from: color2).cgColor

            guard let cgImage = createCGImage(
                color1: cgColor1,
                color2: cgColor2,
                size: size
            ) else {
                return nil
            }

            let swiftUIImage = Image(cgImage, scale: 1.0, label: Text("Generated Dual Color Image"))

            return PreviewAppIcon(image: swiftUIImage, cgImage: cgImage)
        }

        private static func platformColor(from color: Color) -> PlatformColor {
            #if os(macOS)
            return NSColor(color)
            #else
            return UIColor(color)
            #endif
        }
    }

    struct PreviewAppIcon {
        let image: Image
        let cgImage: CGImage

        func toAppIconDetailprovider() -> AppIconDetailProvider {
            .init(image: image, foundColors: AppStyleExtractor.extractProminentColorsForPreview(image: cgImage))
        }
    }
}

#endif
