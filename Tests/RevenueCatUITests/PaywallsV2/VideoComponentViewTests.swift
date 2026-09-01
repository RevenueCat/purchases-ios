//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoComponentViewTests.swift
//
//  Created by RevenueCat.
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit
#endif

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class VideoComponentViewTests: TestCase {

#if os(iOS)
    func testFillModeDoesNotExceedFullscreenWidth() throws {
        let fullScreenSize = CGSize(width: 460, height: 950)
        let view = try Self.makeVideoComponentView(size: fullScreenSize)
        let controller = UIHostingController(rootView: view)

        let fittingSize = controller.sizeThatFits(in: fullScreenSize)

        XCTAssertLessThanOrEqual(fittingSize.width, fullScreenSize.width)
    }
#endif

#if os(iOS)
    /// Moovit reported the video keeping the previous appearance's asset when the device theme is
    /// toggled while the paywall is on screen, while every other component flips. The source is
    /// resolved once, so this asserts the view asks the cache for the dark asset after the switch.
    func testResolvesTheDarkAssetWhenTheColorSchemeChangesWhileOnScreen() throws {
        let requestedURLs: Box<[URL]> = .init([])
        let theme = ThemeBox()
        let view = try Self.makeVideoComponentView(
            size: CGSize(width: 100, height: 100),
            cachedFileURL: { url, _ in
                requestedURLs.value.append(url)
                return nil
            }
        )

        let (window, _) = Self.host(ThemedProbe(theme: theme, content: AnyView(view)))
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertTrue(
            requestedURLs.value.contains(Self.lightVideoURL),
            "The light asset should be resolved on appear. Asked for: \(requestedURLs.value)"
        )

        theme.colorScheme = .dark
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        XCTAssertTrue(
            requestedURLs.value.contains(Self.darkVideoURL),
            "The dark asset was never resolved after the appearance changed. Asked for: \(requestedURLs.value)"
        )
    }
#endif

    func testCalculateMaxWidthClampsNegativeInitialFullscreenFillWidth() {
        let style = Self.makeStyle(
            size: .init(width: .fill, height: .fit(nil)),
            fitMode: .fill,
            padding: .init(top: 0, bottom: 0, leading: 20, trailing: 20),
            margin: .init(top: 0, bottom: 0, leading: 20, trailing: 20)
        )

        // VideoComponentView.size starts at .zero. The first render must not pass a negative
        // maxWidth into FitToAspectRatio, or fullscreen fill-mode paywalls can expand off screen.
        let maxWidth = VideoComponentView.calculateMaxWidth(parentWidth: 0, style: style)

        XCTAssertEqual(maxWidth, 0)
    }

    func testCalculateMaxWidthSubtractsHorizontalSpacingWhenPositive() {
        let style = Self.makeStyle(
            padding: .init(top: 0, bottom: 0, leading: 15, trailing: 10),
            margin: .init(top: 0, bottom: 0, leading: 20, trailing: 5),
            border: .init(color: .init(light: .hex("#000000")), width: 2)
        )

        let maxWidth = VideoComponentView.calculateMaxWidth(parentWidth: 200, style: style)

        XCTAssertEqual(maxWidth, 146)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension VideoComponentViewTests {

#if os(iOS)
    static let lightVideoURL = URL(string: "https://assets.revenuecat.com/video.mp4")!
    static let darkVideoURL = URL(string: "https://assets.revenuecat.com/video-dark.mp4")!

    static func makeVideoComponentView(
        size: CGSize,
        cachedFileURL: @escaping (URL, Checksum?) -> URL? = { _, _ in nil }
    ) throws -> some View {
        let component = PaywallComponent.VideoComponent(
            source: .init(
                light: .init(
                    width: 1080,
                    height: 1920,
                    url: Self.lightVideoURL,
                    checksum: nil,
                    urlLowRes: nil,
                    checksumLowRes: nil
                ),
                dark: .init(
                    width: 1080,
                    height: 1920,
                    url: Self.darkVideoURL,
                    checksum: nil,
                    urlLowRes: nil,
                    checksumLowRes: nil
                )
            ),
            size: .init(width: .fill, height: .fit(nil)),
            fitMode: .fill
        )
        let viewModel = VideoComponentViewModel(
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: component
        )

        return VideoComponentView(viewModel: viewModel, size: size, cachedFileURL: cachedFileURL)
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(
                IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                )
            )
            .environmentObject(
                PaywallPromoOfferCache(
                    subscriptionHistoryTracker: SubscriptionHistoryTracker()
                )
            )
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())
    }
#endif

    static func makeStyle(
        size: PaywallComponent.Size = .init(width: .fill, height: .fit(nil)),
        fitMode: PaywallComponent.FitMode = .fit,
        padding: PaywallComponent.Padding? = nil,
        margin: PaywallComponent.Padding? = nil,
        border: PaywallComponent.Border? = nil
    ) -> VideoComponentStyle {
        VideoComponentStyle(
            showControls: false,
            autoPlay: true,
            loop: true,
            url: URL(string: "https://assets.revenuecat.com/video.mp4")!,
            lowResUrl: nil,
            size: size,
            widthLight: 1920,
            heightLight: 1080,
            widthDark: nil,
            heightDark: nil,
            muteAudio: true,
            fitMode: fitMode,
            padding: padding,
            margin: margin,
            border: border,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        )
    }

}

#if os(iOS)

/// Lets a test flip the appearance of an already-hosted view, the way the device does when the user
/// changes it while the paywall is on screen.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class ThemeBox: ObservableObject {
    @Published var colorScheme: ColorScheme = .light
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ThemedProbe: View {
    @ObservedObject var theme: ThemeBox
    let content: AnyView

    var body: some View {
        self.content.environment(\.colorScheme, self.theme.colorScheme)
    }
}

private final class Box<Value>: @unchecked Sendable {
    var value: Value
    init(_ value: Value) { self.value = value }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension VideoComponentViewTests {

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view.frame(width: 100, height: 100))
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return (window, controller.view)
    }

}

#endif

#endif
