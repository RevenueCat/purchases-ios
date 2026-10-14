//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootViewLayoutSnapshotTests.swift
//

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
import XCTest

#if !os(tvOS) && !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class RootViewLayoutSnapshotTests: BaseSnapshotTest {

    override func setUpWithError() throws {
        try super.setUpWithError()

        // These snapshots render inconsistently on iOS 15.
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("Snapshot is inconsistent on iOS 15")
        }
    }

    func testStickyFooterRootZLayerOnIPadFormSheet() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize
        )

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testStickyFooterOnIPadCardWithoutBottomSafeArea() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 0, trailing: 0)
        )
        .environment(\.userInterfaceIdiom, .pad)

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    /// Scrolled to the bottom, the last row must still clear the sticky footer once the footer
    /// gains its minimum padding.
    func testStickyFooterReservesScrollSpaceOnIPadCard() throws {
        // defaultScrollAnchor is an iOS 17 SDK symbol, so Xcode 14 cannot compile the call at all.
        #if swift(>=5.9)
        guard #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) else {
            throw XCTSkip("defaultScrollAnchor requires iOS 17")
        }

        let viewModel = try PaywallsV2LayoutFixtures.makeTransparentFooterOverScrollableContentViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            safeAreaInsets: EdgeInsets(top: 47, leading: 0, bottom: 0, trailing: 0)
        )
        .environment(\.userInterfaceIdiom, .pad)
        .defaultScrollAnchor(.bottom)

        view.snapshot(
            size: PaywallsV2LayoutFixtures.iPadFormSheetSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
        #else
        throw XCTSkip("defaultScrollAnchor requires the iOS 17 SDK")
        #endif
    }

    func testStickyFooterRootZLayerOnIPhoneFullScreen() throws {
        let viewModel = try PaywallsV2LayoutFixtures.makeStickyFooterRootZLayerViewModel()
        let view = PaywallsV2LayoutFixtures.makeRootView(
            viewModel: viewModel,
            size: Self.fullScreenSize
        )

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testTransparentFooterOverlapsScrollableContent() throws {
        let view = try makeFullScreenSnapshotView(
            PaywallsV2LayoutFixtures.makeTransparentFooterOverScrollableContentViewModel
        )

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testSmallBodyCentersAboveFooter() throws {
        let view = try makeFullScreenSnapshotView(PaywallsV2LayoutFixtures.makeSmallCenteredBodyAboveFooterViewModel)

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testHeaderAndFooterStepReservesHeaderClearance() throws {
        let view = try makeFullScreenSnapshotView(PaywallsV2LayoutFixtures.makeHeaderAndFooterViewModel)

        view.snapshot(
            size: Self.fullScreenSize,
            record: Self.shouldRecordSnapshots,
            separateOSVersions: false
        )
    }

    func testPWENG317ResponsiveHeroSafeAreaOnSimulator() throws {
        try assertPWENG317ResponsiveHero(zlayer: false)
    }

    func testPWENG317ZLayerHeroAndTextSafeAreaOnSimulator() throws {
        try assertPWENG317ResponsiveHero(zlayer: true)
    }

    func testPWENG317PreservesCarouselStateAcrossWidthRules() throws {
        try assertPWENG317ResponsiveHero(zlayer: false, checkViewIdentity: true)
    }

    func testPWENG317EmergePreviewFixturesUseLoadedRenderer() throws {
        for (name, width, zlayer) in [("narrow", 400, false), ("wide", 900, false), ("zlayer", 400, true)] {
            let fixture = ResponsiveHeroSafeAreaPreview(width: CGFloat(width), zlayer: zlayer)
            let controller = UIHostingController(rootView: fixture)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 700))
            window.backgroundColor = .white
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            window.layoutIfNeeded()
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
            defer {
                window.isHidden = true
                window.rootViewController = nil
                window.resignKey()
            }
            let deadline = Date().addingTimeInterval(5)
            var screenshot = Self.pweng317Capture(window)
            while Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
                screenshot = Self.pweng317Capture(window)
                if let redTop = Self.pweng317FirstColoredRow(screenshot, green: false) {
                    if width == 900, Self.pweng317FirstColoredRow(screenshot, green: true) != nil { break }
                    if width == 400, let fixtureTop = Self.pweng317FixtureTop(controller, in: window),
                       abs(CGFloat(redTop) - fixtureTop) <= 1 { break }
                }
            }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "PWENG317-Emerge-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
            let redTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: false))
            // The enclosing SwiftUI host can position this UIKit fixture below a phone's notch.
            // Assert against the fixture's own origin, not the enclosing window's absolute origin.
            let fixtureTop = try XCTUnwrap(Self.pweng317FixtureTop(controller, in: window))
            if width == 900 {
                let greenTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: true))
                XCTAssertGreaterThanOrEqual(CGFloat(greenTop) - fixtureTop, 60)
                XCTAssertGreaterThan(redTop, greenTop)
            } else {
                XCTAssertEqual(CGFloat(redTop), fixtureTop, accuracy: 1)
                XCTAssertNil(Self.pweng317FirstColoredRow(screenshot, green: true))
            }
            if zlayer {
                let textTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: false, blue: true))
                XCTAssertGreaterThanOrEqual(CGFloat(textTop) - fixtureTop, 60)
            }
        }
    }

    private static func pweng317FixtureTop(_ controller: UIViewController, in window: UIWindow) -> CGFloat? {
        if controller is UIHostingController<AnyView> {
            return controller.view.convert(controller.view.bounds.origin, to: window).y
        }
        return controller.children.lazy.compactMap { pweng317FixtureTop($0, in: window) }.first
    }

    private func assertPWENG317ResponsiveHero(zlayer: Bool, checkViewIdentity: Bool = false) throws {
        let redURL = try Self.pweng317ImageURL(color: .red, name: "hero")
        let greenURL = try Self.pweng317ImageURL(color: .green, name: "side")
        func image(_ url: URL, width: PaywallComponent.SizeConstraint) -> PaywallComponent {
            .image(.init(
                source: .init(light: .init(width: 400, height: 240, original: url, heic: url, heicLowRes: url)),
                size: .init(width: width, height: .fixed(240)), fitMode: .fill
            ))
        }
        let side = PaywallComponent.stack(.init(
            visible: false, components: [image(greenURL, width: .fixed(200))],
            overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 800)],
                properties: .init(visible: true)
            )]
        ))
        let textOverlay = PaywallComponent.text(.init(
            text: "overlay", color: .init(light: .hex("#0000FF")),
            size: .init(width: .fill, height: .fixed(60)), fontSize: 16
        ))
        let carousel = PaywallComponent.carousel(.init(pages: [
            .init(components: [textOverlay]), .init(components: [textOverlay])
        ]))
        let config = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(
                components: [side, image(redURL, width: .fill)] + (zlayer ? [textOverlay] : [])
                    + (checkViewIdentity ? [carousel] : []),
                dimension: zlayer ? .zlayer(.top) : .vertical(.leading, .start),
                size: .init(width: .fill, height: .fill), spacing: 0,
                overflow: checkViewIdentity ? .scroll : nil
            ),
            stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
        )
        let provider = PaywallsV2LayoutFixtures.uiConfigProvider
        let state = try PaywallsV2View.createPaywallState(
            componentsConfig: config, componentsLocalizations: ["en_US": ["overlay": .string("Overlay content")]],
            preferredLocales: [Locale(identifier: "en_US")], defaultLocale: "en_US", uiConfigProvider: provider,
            offering: PaywallsV2LayoutFixtures.offering, introEligibilityChecker: Self.eligibleChecker,
            showZeroDecimalPlacePrices: false, colorScheme: .light
        ).get()
        let carouselAppearCount = Self.pweng317ObserveCarouselAppearances(in: state)
        let eligibility = IntroOfferEligibilityContext(introEligibilityChecker: Self.eligibleChecker)
        let package = PackageContext(package: nil, variableContext: .init(packages: []))
        let view = LoadedPaywallsV2View(
            introOfferEligibilityContext: eligibility, paywallState: state, uiConfigProvider: provider,
            selectedPackageContext: package, workflowDefaultPackage: nil, onDismiss: {}
        )
        .measurePaywallWindowSize()
        .environmentObject(eligibility)
        .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        .environmentObject(PurchaseHandler.mock())
        .environment(\.isRunningSnapshots, true)
        let controller = UIHostingController(rootView: view)
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 700))
        window.backgroundColor = .white
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            window.resignKey()
        }
        var mobileTop: Int?
        for (index, width) in [400, 900, 400].enumerated() {
            window.frame.size.width = CGFloat(width)
            controller.view.frame = window.bounds
            window.setNeedsLayout()
            window.layoutIfNeeded()
            let deadline = Date().addingTimeInterval(5)
            var screenshot = Self.pweng317Capture(window)
            while Date() < deadline {
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
                screenshot = Self.pweng317Capture(window)
                let redTop = Self.pweng317FirstColoredRow(screenshot, green: false)
                let greenTop = Self.pweng317FirstColoredRow(screenshot, green: true)
                if zlayer {
                    let blueTop = Self.pweng317FirstColoredRow(screenshot, green: false, blue: true)
                    if let redTop, let blueTop, blueTop >= 60,
                       width == 900 ? redTop >= 60 : redTop <= 1 { break }
                } else if redTop != nil && ((width == 900) == (greenTop != nil)) { break }
            }
            if checkViewIdentity {
                XCTAssertEqual(carouselAppearCount(), 1, "Width rules must preserve the carousel's view state")
            }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "PWENG317-\(zlayer ? "zlayer" : "vertical")-\(index + 1)-width-\(width)"
            attachment.lifetime = .keepAlways
            add(attachment)
            let redTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: false))
            if width == 900 {
                if zlayer {
                    XCTAssertGreaterThanOrEqual(redTop, 60, "Wide ZLayer content must retain safe-area clearance")
                } else {
                    let greenTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: true))
                    XCTAssertGreaterThanOrEqual(greenTop, 60, "Wide leading side must retain safe-area clearance")
                    XCTAssertGreaterThan(redTop, greenTop)
                }
            } else {
                XCTAssertNil(Self.pweng317FirstColoredRow(screenshot, green: true))
                XCTAssertLessThanOrEqual(redTop, 1, "Mobile hero must extend to the top of the hosted window")
                if let mobileTop { XCTAssertEqual(redTop, mobileTop) } else { mobileTop = redTop }
            }
            if zlayer {
                let overlayTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: false, blue: true))
                XCTAssertGreaterThanOrEqual(overlayTop, 60, "Text overlay must remain below the safe area")
            }
        }
    }

    private static func pweng317ObserveCarouselAppearances(in state: PaywallState) -> () -> Int {
        var count = 0
        if case .carousel(let carouselViewModel) = state.rootViewModel.stackViewModel.viewModels.last {
            carouselViewModel.onViewAppear = { count += 1 }
        }
        return { count }
    }

    private static func pweng317ImageURL(color: UIColor, name: String) throws -> URL {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PWENG317-\(name).png")
        try XCTUnwrap(image.pngData()).write(to: url)
        return url
    }

    private static func pweng317Capture(_ window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    private static func pweng317FirstColoredRow(_ image: UIImage, green: Bool, blue: Bool = false) -> Int? {
        guard let image = image.cgImage else { return nil }
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        for row in 0..<height {
            for column in 20..<(width - 20) {
                let index = (row * width + column) * 4
                if blue {
                    if pixels[index + 2] > 200 && pixels[index] < 50 && pixels[index + 1] < 50 { return row }
                } else if green {
                    if pixels[index + 1] > 200 && pixels[index] < 50 && pixels[index + 2] < 50 { return row }
                } else if pixels[index] > 200 && pixels[index + 1] < 50 && pixels[index + 2] < 50 { return row }
            }
        }
        return nil
    }

    private func makeFullScreenSnapshotView(_ makeViewModel: () throws -> RootViewModel) throws -> some View {
        PaywallsV2LayoutFixtures.makeRootView(viewModel: try makeViewModel(), size: Self.fullScreenSize)
    }

}

#endif
