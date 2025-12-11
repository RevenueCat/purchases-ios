//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ColorComputationHelpers.swift
//
//  Created by Jacob Zivan Rakidzich on 12/11/25.

#if canImport(AppKit)
import AppKit
#endif

import SwiftUI

/// Selects the color with the best contrast ratio against a background color.
///
/// Uses WCAG 2.1 contrast ratio calculation to determine which color from the
/// provided array will be most readable/visible against the specified background.
///
/// WCAG contrast ratio guidelines:
/// - 3:1 minimum for large text (18pt+ or 14pt+ bold)
/// - 4.5:1 minimum for normal text (AA compliance)
/// - 7:1 minimum for enhanced contrast (AAA compliance)
///
/// - Parameters:
///   - colors: Array of candidate colors to choose from.
///   - againstColor: The background color to calculate contrast against.
/// - Returns: The color from the array with the highest contrast ratio,
///            or `.black` if the array is empty.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func selectColorWithBestContrast(from colors: [Color], againstColor: Color) -> Color {
    guard !colors.isEmpty else {
        return .black
    }

    let backgroundLuminance = relativeLuminance(of: againstColor)

    var bestColor = colors[0]
    var bestRatio = contrastRatio(luminance1: relativeLuminance(of: colors[0]), luminance2: backgroundLuminance)

    for color in colors.dropFirst() {
        let colorLuminance = relativeLuminance(of: color)
        let ratio = contrastRatio(luminance1: colorLuminance, luminance2: backgroundLuminance)

        if ratio > bestRatio {
            bestRatio = ratio
            bestColor = color
        }
    }

    return bestColor
}

/// Calculates the relative luminance of a color per WCAG 2.1 specification.
///
/// Relative luminance is a measure of the brightness of a color as perceived
/// by the human eye, taking into account that we're more sensitive to green
/// light than red or blue.
///
/// The calculation:
/// 1. Converts sRGB values to linear RGB (removes gamma correction)
/// 2. Applies luminance coefficients based on human eye sensitivity
///
/// - Parameter color: The color to calculate luminance for.
/// - Returns: Relative luminance value between 0 (black) and 1 (white).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private func relativeLuminance(of color: Color) -> Double {
    let rgb = extractRGBComponents(from: color)

    // Convert from sRGB to linear RGB
    let red = linearize(rgb.0)
    let green = linearize(rgb.1)
    let blue = linearize(rgb.2)

    // Apply luminance coefficients (human eye sensitivity)
    return WCAGConstants.redLuminanceCoefficient * red +
           WCAGConstants.greenLuminanceCoefficient * green +
           WCAGConstants.blueLuminanceCoefficient * blue
}

/// Converts an sRGB color component to linear RGB.
///
/// sRGB uses a gamma curve to encode colors in a way that matches human
/// perception. This function reverses that encoding to get the actual
/// light intensity (linear) value.
///
/// The sRGB transfer function has two parts:
/// - A linear section for very dark values (value <= 0.04045)
/// - A gamma curve for the rest (approximately gamma 2.4)
///
/// - Parameter value: sRGB color component value (0-1).
/// - Returns: Linear RGB value (0-1).
func linearize(_ value: Double) -> Double {
    if value <= WCAGConstants.linearizationThreshold {
        return value / WCAGConstants.linearDivisor
    } else {
        return pow((value + WCAGConstants.gammaOffset) / WCAGConstants.gammaDivisor, WCAGConstants.gammaExponent)
    }
}

/// Calculates the contrast ratio between two luminance values.
///
/// The contrast ratio is defined by WCAG as:
/// (L1 + 0.05) / (L2 + 0.05)
/// where L1 is the lighter luminance and L2 is the darker luminance.
///
/// The 0.05 offset accounts for ambient light and prevents division by zero.
///
/// Contrast ratio ranges from 1:1 (no contrast, same color) to 21:1 (max contrast, black on white).
///
/// - Parameters:
///   - luminance1: Relative luminance of the first color (0-1).
///   - luminance2: Relative luminance of the second color (0-1).
/// - Returns: The contrast ratio (1.0 to 21.0).
private func contrastRatio(luminance1: Double, luminance2: Double) -> Double {
    let lighter = max(luminance1, luminance2)
    let darker = min(luminance1, luminance2)
    return (lighter + WCAGConstants.contrastOffset) / (darker + WCAGConstants.contrastOffset)
}

/// Extracts RGB components from a SwiftUI `Color` using platform-specific APIs.
///
/// - Parameter color: The SwiftUI `Color` to extract components from.
/// - Returns: A tuple of (red, green, blue) values in the range 0-1.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func extractRGBComponents(from color: Color) -> (Double, Double, Double) {
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

/// Constants defined by WCAG 2.1 for calculating relative luminance and contrast ratios.
/// These are standardized values, not arbitrary choices.
/// Reference: https://www.w3.org/WAI/GL/wiki/Relative_luminance
enum WCAGConstants {
    /// Luminance coefficient for the red channel.
    /// Human eyes are less sensitive to red than green.
    static let redLuminanceCoefficient = 0.2126

    /// Luminance coefficient for the green channel.
    /// Human eyes are most sensitive to green light.
    static let greenLuminanceCoefficient = 0.7152

    /// Luminance coefficient for the blue channel.
    /// Human eyes are least sensitive to blue.
    static let blueLuminanceCoefficient = 0.0722

    /// Threshold for sRGB linearization.
    /// Below this value, the gamma curve is approximately linear.
    /// This is part of the sRGB color space specification.
    static let linearizationThreshold = 0.04045

    /// Divisor for linear portion of sRGB gamma curve.
    /// Used when the color value is below the linearization threshold.
    static let linearDivisor = 12.92

    /// Offset added before applying gamma correction.
    /// Part of the sRGB transfer function specification.
    static let gammaOffset = 0.055

    /// Divisor used in gamma correction formula.
    /// Calculated as (1 + gammaOffset) = 1.055.
    static let gammaDivisor = 1.055

    /// Gamma exponent for sRGB color space.
    /// Approximates the actual sRGB curve which varies slightly.
    static let gammaExponent = 2.4

    /// Small offset added to luminance values when calculating contrast ratio.
    /// Prevents division by zero and accounts for ambient light.
    /// This value is defined by WCAG specification.
    static let contrastOffset = 0.05
}

/// Constants used in the prominent color extraction algorithm.
enum ColorExtractionConstants {
    /// Maximum number of pixels to sample from the image.
    /// Sampling reduces processing time while maintaining accuracy.
    /// 10,000 samples provides a good balance between performance and color detection quality.
    static let maxPixelSamples = 10000

    /// The divisor used to quantize (reduce) color precision.
    /// Dividing RGB values by 32 reduces 256 possible values per channel to 8,
    /// grouping similar colors together. This helps identify dominant colors
    /// by combining nearly-identical shades into single buckets.
    /// Value of 32 = 256/8, creating 8 color levels per channel (512 total possible colors).
    static let colorQuantizationDivisor: UInt8 = 32

    /// Minimum alpha (opacity) value for a pixel to be considered.
    /// Pixels with alpha <= 128 (50% transparent or more) are ignored
    /// to avoid counting transparent/semi-transparent areas.
    /// Range: 0 (fully transparent) to 255 (fully opaque).
    static let minimumAlphaThreshold: UInt8 = 128

    /// Minimum combined RGB brightness for a color to be considered.
    /// Filters out very dark colors (near-black) that aren't visually distinctive.
    /// Calculated as: quantizedR + quantizedG + quantizedB.
    /// Value of 30 ≈ RGB(10,10,10) after quantization, very dark gray.
    static let minimumBrightnessThreshold = 30

    /// Maximum combined RGB brightness for a color to be considered.
    /// Filters out very bright colors (near-white) that aren't visually distinctive.
    /// Calculated as: quantizedR + quantizedG + quantizedB.
    /// Value of 720 ≈ RGB(240,240,240) after quantization, very light gray.
    /// Maximum possible value would be 224*3 = 672 for quantized, but we use 720
    /// to account for the actual max of 255*3 = 765.
    static let maximumBrightnessThreshold = 720

    /// Minimum Euclidean distance between colors in RGB space (normalized 0-1).
    /// Colors closer than this threshold are considered "too similar".
    /// This ensures the returned colors are visually distinct from each other.
    /// Value of 0.15 in normalized RGB space ≈ 38 in 0-255 scale.
    /// For reference: sqrt(3) ≈ 1.73 is the max distance (black to white).
    static let minimumColorDistance = 0.05

    /// Number of bytes per pixel in RGBA format.
    /// Each pixel has 4 components: Red, Green, Blue, Alpha (1 byte each).
    static let bytesPerPixel = 4

    /// Number of bits per color component (R, G, or B).
    /// Standard 8-bit color depth allows 256 values (0-255) per channel.
    static let bitsPerComponent = 8

    /// Minimum Euclidean distance a color must be from pure black (0,0,0) or pure white (1,1,1).
    /// Colors closer than this threshold to black or white are excluded from results.
    /// This ensures returned colors have enough "color" to be visually interesting
    /// and will provide reasonable contrast against both light and dark backgrounds.
    /// Value of 0.20 in normalized RGB space ≈ 51 in 0-255 scale.
    /// A color like RGB(50,50,50) or RGB(205,205,205) would be excluded.
    static let minimumDistanceFromBlackWhite = 0.60
}
