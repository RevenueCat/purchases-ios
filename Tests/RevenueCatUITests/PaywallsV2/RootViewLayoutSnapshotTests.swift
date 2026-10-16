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

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
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
        try assertPWENG317ResponsiveHero(layout: .vertical)
    }

    func testPWENG317ZLayerHeroAndTextSafeAreaOnSimulator() throws {
        try assertPWENG317ResponsiveHero(layout: .overlay)
    }

    func testPWENG317PreservesCarouselStateAcrossWidthRules() throws {
        try assertPWENG317ResponsiveHero(layout: .vertical, checkViewIdentity: true)
    }

    func testPWENG317DoesNotAddSafeAreaPaddingInsideNestedZLayer() throws {
        try assertPWENG317ResponsiveHero(layout: .nestedCard)
    }

    func testPWENG317PreservesExistingHeaderZLayerLayout() throws {
        try assertPWENG317ResponsiveHero(layout: .overlay, withHeader: true)
    }

    func testPWENG317PreservesLeadingNestedZLayerInsets() throws {
        try assertPWENG317ResponsiveHero(layout: .leadingNestedCard)
    }

    func testPWENG317HeroContainerAndRootOverlayKeepSafeAreaClearance() throws {
        try assertPWENG317ResponsiveHero(layout: .heroContainer)
    }

    private enum HeroLayout {
        case vertical, overlay, nestedCard, leadingNestedCard, heroContainer
    }

    private func assertPWENG317ResponsiveHero(
        layout: HeroLayout, checkViewIdentity: Bool = false, withHeader: Bool = false
    ) throws {
        let zlayer = layout != .vertical
        let nestedZLayer = layout == .nestedCard || layout == .leadingNestedCard
        let leadingNestedZLayer = layout == .leadingNestedCard
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
        let components = [side, image(redURL, width: .fill)] + (zlayer ? [textOverlay] : [])
            + (checkViewIdentity ? [carousel] : [])
        let rootComponents = Self.pweng317RootComponents(
            layout: layout, components: components, hero: image(redURL, width: .fill), text: textOverlay
        )
        let config = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(
                components: rootComponents,
                dimension: zlayer && !nestedZLayer ? .zlayer(.top) : .vertical(.leading, .start),
                size: .init(width: .fill, height: .fill), spacing: 0,
                overflow: checkViewIdentity ? .scroll : nil
            ),
            header: withHeader ? .init(stack: .init(components: [.text(.init(
                text: "overlay", color: .init(light: .hex("#000000")),
                size: .init(width: .fill, height: .fixed(60)), fontSize: 16
            ))])) : nil,
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
                    if Self.pweng317OverlayIsReady(
                        redTop: redTop, blueTop: blueTop, width: width,
                        nestedZLayer: nestedZLayer, withHeader: withHeader || leadingNestedZLayer
                    ) { break }
                } else if redTop != nil && ((width == 900) == (greenTop != nil)) { break }
            }
            XCTAssertEqual(carouselAppearCount(), checkViewIdentity ? 1 : 0,
                           "Width rules must preserve the carousel's view state")
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "PWENG317-\(zlayer ? "zlayer" : "vertical")-\(index + 1)-width-\(width)"
            attachment.lifetime = .keepAlways
            add(attachment)
            let redTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: false))
            if nestedZLayer || withHeader {
                try assertPWENG317ExistingInsets(
                    screenshot, redTop: redTop, withHeader: withHeader || leadingNestedZLayer
                )
                continue
            }
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

    private static func pweng317RootComponents(
        layout: HeroLayout, components: [PaywallComponent], hero: PaywallComponent, text: PaywallComponent
    ) -> [PaywallComponent] {
        switch layout {
        case .nestedCard, .leadingNestedCard:
            return (layout == .leadingNestedCard ? [] : [hero]) + [.stack(.init(
                components: components, dimension: .zlayer(.top), size: .init(width: .fill, height: .fixed(240))
            ))]
        case .heroContainer:
            return [components[0], .stack(.init(components: [.stack(.init(
                components: [hero, text], dimension: .zlayer(.top)
            ))])), text]
        default:
            return components
        }
    }

    private static func pweng317OverlayIsReady(
        redTop: Int?, blueTop: Int?, width: Int, nestedZLayer: Bool, withHeader: Bool
    ) -> Bool {
        guard let redTop, let blueTop else { return false }
        if withHeader { return blueTop - redTop < 60 }
        if nestedZLayer { return (240..<300).contains(blueTop) }
        return blueTop >= 60 && (width == 900 ? redTop >= 60 : redTop <= 1)
    }

    private func assertPWENG317ExistingInsets(_ screenshot: UIImage, redTop: Int, withHeader: Bool) throws {
        let textTop = try XCTUnwrap(Self.pweng317FirstColoredRow(screenshot, green: false, blue: true))
        if withHeader {
            XCTAssertGreaterThanOrEqual(redTop, 60, "The existing leading layout keeps its clearance")
            XCTAssertGreaterThanOrEqual(textTop, redTop)
            XCTAssertLessThan(textTop - redTop, 60, "Existing layouts must not gain another safe-area inset")
        } else {
            XCTAssertLessThanOrEqual(redTop, 1)
            XCTAssertGreaterThanOrEqual(textTop, 240)
            XCTAssertLessThan(textTop, 300, "A nested card must not gain another top safe-area inset")
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
