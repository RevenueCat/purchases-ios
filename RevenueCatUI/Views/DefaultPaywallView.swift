//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultPaywallView.swift
//
//  Created by Jacob Zivan Rakidzich on 12/11/25.
//
// swiftlint:disable file_length

#if canImport(AppKit)
import AppKit
#endif
import CoreGraphics
import RevenueCat
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

fileprivate extension Color {
    static let revenueCatBrandRed = Color(red: 0.949, green: 0.329, blue: 0.357) // #f2545b
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallView: View {

    init(
        handler: PurchaseHandler,
        warning: PaywallWarning? = nil,
        offering: Offering?,
        appName: String = AppStyleExtractor.getAppName(),
        iconDetailProvider: AppIconDetailProvider = AppIconDetailProvider()
    ) {
        self.handler = handler
        self.warning = warning
        self.appName = appName
        self.appIconDetailProvider = iconDetailProvider
        if let packages = offering?.availablePackages, !packages.isEmpty {
            self.selected = packages.first
            self.products = packages
        } else {
            self.products = []
        }
    }

    let handler: PurchaseHandler
    let appName: String

    @State private var warning: PaywallWarning?
    @State private var products: [Package]
    @State private var selected: Package?

    @ObservedObject var appIconDetailProvider: AppIconDetailProvider

    var iconColor: Color {
        if appIconDetailProvider.foundColors.isEmpty {
            return .accentColor
        }

        return selectColorWithBestContrast(
            from: appIconDetailProvider.foundColors,
            againstColor: colorScheme == .dark ? .black : .white
        )
    }

    var foregroundOnAccentColor: Color {
        if shouldShowWarning {
            return .white
        }

        return selectColorWithBestContrast(
            from: appIconDetailProvider.foundColors + [colorScheme == .dark ? .black : .white],
            againstColor: iconColor
        )
    }

    @Environment(\.colorScheme) var colorScheme

    private var mainColor: Color {
        if shouldShowWarning {
            return .revenueCatBrandRed
        } else {
            return iconColor
        }
    }

    var shouldShowWarning: Bool {
        var showWarning = false
        #if DEBUG
        showWarning = (warning != nil)
        #endif
        return showWarning
    }

    @ViewBuilder
    var warningTitle: some View {
        if shouldShowWarning {
            Text("RevenueCat Paywalls")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var body: some View {
        VStack {
            warningTitle
            Spacer()

            if shouldShowWarning, let warning {
                DefaultPaywallWarning(warning: warning)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    ZStack {
                        appIconDetailProvider.image
                            .resizable()
                            .blur(radius: 48)
                            .opacity(0.2)
                            .accessibilityHidden(true)
                        appIconDetailProvider.image
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 31))
                            .accessibilityHidden(true)
                    }
                    .frame(width: 120, height: 120)
                    .shadow(color: mainColor.opacity(0.2), radius: 6, x: 0, y: 2)
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("App Icon Image")

                    Text(appName)
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            Spacer()

            VStack {
                ForEach(products) { product in
                    DefaultProductCell(
                        product: product,
                        accentColor: mainColor,
                        selectedFontColor: foregroundOnAccentColor,
                        selected: $selected
                    )
                }
            }
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            if !products.isEmpty {
                VStack {
                    let purchaseButton = Button {
                        if let selected {
                            Task(priority: .userInitiated) {
                                try await handler.purchase(package: selected)
                            }
                        }
                    } label: {
                        Text("Purchase")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(foregroundOnAccentColor)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: 480) // For iPad or macOS

                    if #available(watchOS 9.0, *) {
                        purchaseButton
                            #if !os(tvOS)
                            .controlSize(.large)
                            #endif
                    } else {
                        purchaseButton
                    }

                    let restoreButton = Button {
                        Task(priority: .userInitiated) {
                            try await handler.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                    }
                        .padding(.top, 8)

                    if #available(watchOS 9.0, *) {
                        restoreButton
                            #if !os(tvOS)
                            .controlSize(.large)
                            #endif
                            .tint(Color.primary)
                    } else {
                        restoreButton
                    }
                }
                .padding()
            }

        }
        .fillWithReadableContentWidth()
        .background {
            LinearGradient(colors: [
                mainColor.opacity(0.2),
                mainColor.opacity(0)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
        #if !os(watchOS)
        .tint(mainColor)
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultProductCell: View {
    let product: Package
    let accentColor: Color
    let selectedFontColor: Color
    @Binding var selected: Package?

    private var isSelected: Bool {
        selected == product
    }

    var body: some View {
        Button {
            withAnimation {
                selected = product
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .opacity(isSelected ? 1 : 0.5)
                    .accessibilityHidden(true)
                Text(product.storeProduct.localizedTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(product.localizedPriceString)
                    .font(.subheadline)
                    .monospacedDigit()
            }
            .foregroundColor(isSelected ? selectedFontColor : Color.primary)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? accentColor : .secondary.opacity(0.3))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .frame(maxWidth: 560)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultPaywallWarning: View {
    let warning: PaywallWarning

    var body: some View {
        VStack(alignment: .center, spacing: 16) {

            Image("default-paywall", bundle: .module)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: 8) {
                Text(warning.title)
                    .font(.title3)
                    .bold()
                Text(warning.bodyText)
                    .font(.subheadline)
            }
            if let url = warning.helpURL {
                let link = Link(destination: url) {
                    Text("Go to Dashboard")
                        .bold()
                }.buttonStyle(.bordered)

                if #available(watchOS 9.0, *) {
                    link.tint(.revenueCatBrandRed)
                } else {
                    link.foregroundStyle(Color.revenueCatBrandRed)
                }
            }

        }
        .multilineTextAlignment(.center)
    }
}

extension View {
    // centers content but doesn't allow it to get too wide, this looks better on full screens like an ipad
    func fillWithReadableContentWidth() -> some View {
        self
        // UIKit used to have readable content guides, they started around 624 pixels and scaled up with dynamic fonts
        // This is just a sensible default that is close to the readable guide
            .frame(maxWidth: 630)
            .frame(maxWidth: .infinity)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class AppIconDetailProvider: ObservableObject {

    let image: Image
    @Published var foundColors: [Color]

    init() {
        image = AppStyleExtractor.getAppIcon()
        let appIconCGImage: CGImage? = AppStyleExtractor.getPlatformAppIconCGImage()
        foundColors = []

        if let appIconCGImage {
            AppStyleExtractor.getProminentColorsFromAppIcon(image: appIconCGImage) {
                self.foundColors = $0
            }
        }
    }

    #if DEBUG
    // For emerge snapshot tests to render correctly, we need scan the image on the main thread
    // so there is no delay between initial render and the found colors being applied to the view
    init(
        image: Image,
        foundColors: [Color]
    ) {
        self.image = image
        self.foundColors = foundColors
    }
    #endif
}

#if DEBUG

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
