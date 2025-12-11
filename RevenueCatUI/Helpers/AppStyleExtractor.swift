//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppDetails.swift
//
//  Created by Jacob Zivan Rakidzich on 12/11/25.

#if canImport(AppKit)
import AppKit
#endif

import SwiftUI

/// Provides utilities for accessing app metadata and visual assets.
///
/// This enum contains static methods for retrieving information about the current app,
/// including its name, icon, and prominent colors from the icon.
///
/// All methods work across iOS, macOS, and tvOS platforms.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
enum AppStyleExtractor {

    /// Retrieves the name of the app's primary icon from the bundle.
    ///
    /// This method navigates the Info.plist structure to find the icon filename.
    /// The icon name can be used with `UIImage(named:)` on iOS/tvOS.
    ///
    /// - Returns: The icon filename, or an empty string if not found.
    private static func appIconName() -> String {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let lastIconName = iconFiles.last else {
            return ""
        }
        return lastIconName
    }

    /// Retrieves the display name of the application.
    ///
    /// Attempts to get the localized display name first (`CFBundleDisplayName`),
    /// falling back to the bundle name (`CFBundleName`) if not available.
    ///
    /// - Returns: The app's display name, or an empty string if neither is found.
    static func getAppName() -> String {
        let bundle = Bundle.main
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }
        if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }
        return ""
    }

    /// Returns the app's icon as a SwiftUI `Image`.
    ///
    /// - On macOS: Returns the application icon from `NSApplication.shared`.
    /// - On iOS/tvOS: Returns the icon loaded by name from the asset catalog.
    ///
    /// - Returns: A SwiftUI `Image` containing the app icon, or an empty image if unavailable.
    static func getAppIcon() -> Image {
        #if os(macOS)
        return Image(nsImage: NSApplication.shared.applicationIconImage)
        #elseif canImport(UIKit)
        if let image = UIImage(named: appIconName()) {
            return Image(uiImage: image)
        }
        #endif
        return Image("")
    }

    /// Extracts the most prominent colors from the app icon asynchronously.
    ///
    /// This method performs color extraction on a background thread to avoid
    /// blocking the main thread, then delivers results on the main thread.
    ///
    /// The algorithm:
    /// 1. Samples pixels from the app icon (up to 10,000 samples for performance)
    /// 2. Quantizes colors to group similar shades together
    /// 3. Filters out transparent, very dark, and very bright pixels
    /// 4. Sorts colors by frequency (most common first)
    /// 5. Removes colors that are too similar to already-selected colors
    ///
    /// - Parameter completion: Closure called on the main thread with an array of up to 4 prominent `Color` values.
    static func getProminentColorsFromAppIcon(completion: @escaping ([Color]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let colors = extractProminentColors(count: 2)
            DispatchQueue.main.async {
                completion(colors)
            }
        }
    }

    /// Extracts the most prominent colors from the app icon using async/await.
    ///
    /// This is an async wrapper around `getProminentColorsFromAppIcon(completion:)`.
    /// See that method for details on the extraction algorithm.
    ///
    /// - Returns: An array of up to 4 prominent `Color` values from the app icon.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    static func getProminentColorsFromAppIcon() async -> [Color] {
        await withCheckedContinuation { continuation in
            getProminentColorsFromAppIcon { colors in
                continuation.resume(returning: colors)
            }
        }
    }

    /// Performs the actual color extraction from the app icon.
    ///
    /// This method:
    /// 1. Gets the app icon as a `CGImage`
    /// 2. Creates a bitmap context to access raw pixel data
    /// 3. Samples pixels at regular intervals (for performance)
    /// 4. Quantizes each pixel's color to reduce the color space
    /// 5. Counts occurrences of each quantized color
    /// 6. Selects the most frequent colors that are visually distinct
    ///
    /// - Parameter count: The maximum number of colors to return.
    /// - Returns: An array of distinct prominent colors, sorted by frequency.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private static func extractProminentColors(count: Int, image: CGImage? = getPlatformAppIconCGImage()) -> [Color] {
        guard let cgImage = image else {
            return []
        }

        let width = cgImage.width
        let height = cgImage.height
        let totalPixels = width * height

        guard totalPixels > 0 else { return [] }

        // Create a bitmap context to access raw pixel data in RGBA format
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: ColorExtractionConstants.bitsPerComponent,
            bytesPerRow: width * ColorExtractionConstants.bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            return []
        }

        let data = pixelData.bindMemory(to: UInt8.self, capacity: totalPixels * ColorExtractionConstants.bytesPerPixel)

        // Dictionary to count occurrences of each quantized color
        // Key: packed RGB value (R << 16 | G << 8 | B), Value: count
        var colorCounts: [UInt32: Int] = [:]

        // Calculate step size to sample approximately maxPixelSamples pixels
        let sampleStep = max(1, totalPixels / ColorExtractionConstants.maxPixelSamples)

        for pixel in stride(from: 0, to: totalPixels, by: sampleStep) {
            let offset = pixel * ColorExtractionConstants.bytesPerPixel
            let red = data[offset]
            let green = data[offset + 1]
            let blue = data[offset + 2]
            let alpha = data[offset + 3]

            // Skip pixels that are mostly transparent
            guard alpha > ColorExtractionConstants.minimumAlphaThreshold else { continue }

            // Quantize colors by reducing precision (groups similar colors together)
            let quantizationDivisor = ColorExtractionConstants.colorQuantizationDivisor
            let quantizedR = (red / quantizationDivisor) * quantizationDivisor
            let quantizedG = (green / quantizationDivisor) * quantizationDivisor
            let quantizedB = (blue / quantizationDivisor) * quantizationDivisor

            // Calculate simple brightness as sum of RGB components
            let brightness = Int(quantizedR) + Int(quantizedG) + Int(quantizedB)

            // Skip very dark (near-black) and very bright (near-white) colors
            if brightness < ColorExtractionConstants.minimumBrightnessThreshold ||
               brightness > ColorExtractionConstants.maximumBrightnessThreshold {
                continue
            }

            // Pack RGB into a single UInt32 for use as dictionary key
            let key = (UInt32(quantizedR) << 16) | (UInt32(quantizedG) << 8) | UInt32(quantizedB)
            colorCounts[key, default: 0] += 1
        }

        // Sort colors by frequency (most common first)
        let sortedColors = colorCounts.sorted { $0.value > $1.value }

        var prominentColors: [Color] = []
        // Reference colors for black/white distance check
        let black = (0.0, 0.0, 0.0)
        let white = (1.0, 1.0, 1.0)

        for (colorKey, _) in sortedColors {
            // Unpack RGB values from the key and normalize to 0-1 range
            let red = Double((colorKey >> 16) & 0xFF) / 255.0
            let green = Double((colorKey >> 8) & 0xFF) / 255.0
            let blue = Double(colorKey & 0xFF) / 255.0

            let colorTuple = (red, green, blue)

            // Skip colors that are too close to pure black or pure white
            let distanceFromBlack = colorDistance(color1: colorTuple, color2: black)
            let distanceFromWhite = colorDistance(color1: colorTuple, color2: white)

            if distanceFromBlack < ColorExtractionConstants.minimumDistanceFromBlackWhite ||
               distanceFromWhite < ColorExtractionConstants.minimumDistanceFromBlackWhite {
                continue
            }

            let newColor = Color(red: red, green: green, blue: blue)

            // Check if this color is too similar to any already-selected color
            let isTooSimilar = prominentColors.contains { existingColor in
                colorDistance(
                    color1: colorTuple,
                    color2: extractRGB(from: existingColor)
                ) < ColorExtractionConstants.minimumColorDistance
            }

            if !isTooSimilar {
                prominentColors.append(newColor)
                if prominentColors.count >= count {
                    break
                }
            }
        }

        return prominentColors
    }

    /// Retrieves the app icon as a `CGImage` using platform-specific APIs.
    ///
    /// - On macOS: Converts the `NSImage` from `NSApplication.shared.applicationIconImage`.
    /// - On iOS/tvOS: Loads the icon by name using `UIImage(named:)`.
    ///
    /// - Returns: The app icon as a `CGImage`, or `nil` if unavailable.
    private static func getPlatformAppIconCGImage() -> CGImage? {
        #if os(macOS)
        if let nsImage = NSApplication.shared.applicationIconImage {
            var rect = NSRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
            return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }
        #elseif canImport(UIKit)
        guard let uiImage = UIImage(named: appIconName()) else { return nil }
        return uiImage.cgImage
        #endif
        return nil
    }

    /// Extracts RGB components from a SwiftUI `Color`.
    ///
    /// Uses platform-specific APIs to convert the color to RGB values.
    ///
    /// - Parameter color: The SwiftUI `Color` to extract components from.
    /// - Returns: A tuple of (red, green, blue) values in the range 0-1.
    private static func extractRGB(from color: Color) -> (Double, Double, Double) {
        #if os(macOS)
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return (0, 0, 0)
        }
        return (Double(rgbColor.redComponent), Double(rgbColor.greenComponent), Double(rgbColor.blueComponent))
        #elseif canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
        #else
        return (0, 0, 0)
        #endif
    }

    /// Calculates the Euclidean distance between two colors in RGB space.
    ///
    /// This measures how "different" two colors appear. The distance is calculated
    /// in normalized RGB space (0-1 per channel), so the maximum possible distance
    /// is √3 ≈ 1.73 (from black to white).
    ///
    /// Note: This is a simple RGB distance, not perceptually uniform. For more
    /// accurate perceptual difference, consider using LAB color space.
    ///
    /// - Parameters:
    ///   - color1: First color as (red, green, blue) tuple, values 0-1.
    ///   - color2: Second color as (red, green, blue) tuple, values 0-1.
    /// - Returns: The Euclidean distance between the colors.
    private static func colorDistance(color1: (Double, Double, Double), color2: (Double, Double, Double)) -> Double {
        let dred = color1.0 - color2.0
        let dgreen = color1.1 - color2.1
        let dblue = color1.2 - color2.2
        return sqrt(dred * dred + dgreen * dgreen + dblue * dblue)
    }
}
