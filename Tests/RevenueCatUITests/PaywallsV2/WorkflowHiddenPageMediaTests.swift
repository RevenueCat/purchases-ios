//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowHiddenPageMediaTests.swift

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Workflow keeps every visited step mounted off-screen so its state survives back-navigation,
/// which means a hidden page's `onDisappear` never fires and its auto-advancing carousel keeps
/// ticking at opacity 0. These tests drive a real carousel through the `isPageActive` flag and
/// read the rendered pixels, so they assert the timer actually stops rather than that a helper
/// returns the right `Bool`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WorkflowHiddenPageMediaTests: TestCase {

    func testCarouselKeepsAutoAdvancingWhileTheWorkflowPageIsOnScreen() throws {
        let activation = PageActivation(isActive: true)
        let window = try Self.hostCarousel(activation: activation)
        defer { Self.tearDown(window) }

        // Sanity check for the two tests below: with the page on-screen the timer runs, so the
        // visible slide changes on its own. Without this the "it stopped" assertion is vacuous.
        let initial = try Self.sampleSlideColor(window)
        XCTAssertTrue(
            try Self.slideChanges(from: initial, in: window, within: 1.5),
            "Auto-advance never ran, so the rest of this suite would pass for the wrong reason"
        )
    }

    func testCarouselStopsAutoAdvancingWhileTheWorkflowPageIsHidden() throws {
        let activation = PageActivation(isActive: true)
        let window = try Self.hostCarousel(activation: activation)
        defer { Self.tearDown(window) }

        XCTAssertTrue(
            try Self.slideChanges(from: try Self.sampleSlideColor(window), in: window, within: 1.5),
            "Auto-advance never ran before hiding the page"
        )

        // Navigate to another workflow step. The page stays mounted, it just goes off-screen.
        activation.isActive = false
        Self.pump(Self.settleInterval)

        // Anything already animating when the flag flipped has landed by now, so any further
        // change is the timer still firing on a page the user cannot see.
        let afterHiding = try Self.sampleSlideColor(window)
        XCTAssertFalse(
            try Self.slideChanges(from: afterHiding, in: window, within: Self.quiesceInterval),
            "The carousel kept auto-advancing on a hidden workflow page"
        )
    }

    func testCarouselResumesAutoAdvancingWhenTheWorkflowPageComesBack() throws {
        let activation = PageActivation(isActive: true)
        let window = try Self.hostCarousel(activation: activation)
        defer { Self.tearDown(window) }

        XCTAssertTrue(
            try Self.slideChanges(from: try Self.sampleSlideColor(window), in: window, within: 1.5),
            "Auto-advance never ran, so there is nothing to resume"
        )

        activation.isActive = false
        Self.pump(Self.settleInterval)
        let whileHidden = try Self.sampleSlideColor(window)

        // Navigate back to the step.
        activation.isActive = true
        XCTAssertTrue(
            try Self.slideChanges(from: whileHidden, in: window, within: 1.5),
            "The carousel never restarted after the workflow page came back on-screen"
        )
    }

    /// The carousel tests above cover the timer. This covers the other half of the fix, and the
    /// worse offender: a video outside a carousel is unconditionally playable today
    /// (`carouselState?.isActiveOrNeighbor ?? true`), so on a hidden page it keeps an `AVPlayer`
    /// alive at opacity 0. `isPlayable == false` removes `VideoPlayerView` from the hierarchy
    /// entirely, so the player view's presence is the observable signal, no real video needed.
    func testVideoPlayerIsTornDownWhileTheWorkflowPageIsHidden() throws {
        let activation = PageActivation(isActive: true)
        let window = try Self.hostVideo(activation: activation)
        defer { Self.tearDown(window) }

        XCTAssertTrue(
            Self.containsPlayerView(window),
            "Video player never mounted, so the teardown assertion below would be vacuous"
        )

        activation.isActive = false
        Self.pump(Self.settleInterval)

        XCTAssertFalse(
            Self.containsPlayerView(window),
            "The video player stayed alive on a hidden workflow page"
        )

        // Coming back re-creates it (`playerRefreshToggle` changes the view's identity).
        activation.isActive = true
        Self.pump(Self.settleInterval)

        XCTAssertTrue(
            Self.containsPlayerView(window),
            "The video player did not come back when the workflow page returned on-screen"
        )
    }

}

// MARK: - Host

/// Mirrors what `WorkflowPaywallView.seenPageView` does to a page it keeps mounted but hidden:
/// same subtree, same environment, only `isPageActive` differs.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class PageActivation: ObservableObject {

    @Published var isActive: Bool

    init(isActive: Bool) {
        self.isActive = isActive
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct HiddenPageCarouselHost: View {

    @ObservedObject var activation: PageActivation
    let viewModel: CarouselComponentViewModel

    var body: some View {
        CarouselComponentView(viewModel: self.viewModel, onDismiss: {})
            .environment(
                \.workflowRenderingContext,
                WorkflowRenderingContext(
                    pageTransition: .init(
                        pageOffset: 0,
                        headerButtonOpacity: self.activation.isActive ? 1 : 0,
                        isTransitioning: false,
                        isPageActive: self.activation.isActive
                    )
                )
            )
            // Deliberately not `.opacity(0)` when inactive, even though that is what production
            // does: the rendered pixels are how this test sees the timer, and hiding the subtree
            // would make it pass whether or not the carousel stopped. Mounted-and-live is the part
            // that matters, and that is unchanged either way.
            .frame(width: WorkflowHiddenPageMediaTests.windowSize.width,
                   height: WorkflowHiddenPageMediaTests.windowSize.height)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct HiddenPageVideoHost: View {

    @ObservedObject var activation: PageActivation
    let viewModel: VideoComponentViewModel

    var body: some View {
        VideoComponentView(
            viewModel: self.viewModel,
            size: WorkflowHiddenPageMediaTests.windowSize
        )
        .environment(
            \.workflowRenderingContext,
            WorkflowRenderingContext(
                pageTransition: .init(
                    pageOffset: 0,
                    headerButtonOpacity: self.activation.isActive ? 1 : 0,
                    isTransitioning: false,
                    isPageActive: self.activation.isActive
                )
            )
        )
        .frame(width: WorkflowHiddenPageMediaTests.windowSize.width,
               height: WorkflowHiddenPageMediaTests.windowSize.height)
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WorkflowHiddenPageMediaTests {

    static let windowSize = CGSize(width: 200, height: 200)

    /// One auto-advance every 150ms (100ms per slide + 50ms transition).
    static let msTimePerPage = 100
    static let msTransitionTime = 50

    /// Long enough for an in-flight slide animation to land after the flag flips.
    static let settleInterval: TimeInterval = 0.4
    /// Several auto-advance intervals, so a still-running timer would be caught.
    static let quiesceInterval: TimeInterval = 0.9

    static func hostCarousel(activation: PageActivation) throws -> UIWindow {
        let viewModel = try Self.makeAutoAdvancingCarouselViewModel()
        let packageContext = PackageContext(package: nil, variableContext: .init(packages: []))

        let view = HiddenPageCarouselHost(activation: activation, viewModel: viewModel)
            .environmentObject(packageContext)
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(
                subscriptionHistoryTracker: SubscriptionHistoryTracker()
            ))
            .environment(\.screenCondition, .compact)
            .environment(\.componentViewState, .default)
            .environment(\.safeAreaInsets, EdgeInsets())
            .environment(\.selectedPackageId, nil)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        Self.pump(0.2)

        // Two of these tests assert the rendered slide *stops* changing. If the carousel never
        // rendered at all, the sampled pixel would be a constant background and they would pass
        // for the wrong reason, so refuse to hand back a host that isn't showing a real slide.
        let rendered = try Self.sampleSlideColor(window)
        XCTAssertTrue(
            Self.slideColors.contains(rendered),
            "Carousel did not render a slide (sampled \(rendered), expected one of \(Self.slideColors))"
        )

        return window
    }

    static func hostVideo(activation: PageActivation) throws -> UIWindow {
        let component = PaywallComponent.VideoComponent(
            source: .init(
                light: .init(
                    width: 1080,
                    height: 1920,
                    // A local path that does not exist: the component still takes its "nothing
                    // cached" branch and mounts a player, it just never decodes anything. Keeps
                    // the test off the network.
                    url: URL(fileURLWithPath: "/dev/null/workflow-hidden-page.mp4"),
                    checksum: nil,
                    urlLowRes: nil,
                    checksumLowRes: nil
                )
            ),
            showControls: false,
            autoPlay: true,
            size: .init(width: .fill, height: .fit(nil)),
            fitMode: .fill
        )
        let viewModel = VideoComponentViewModel(
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: component
        )

        let view = HiddenPageVideoHost(activation: activation, viewModel: viewModel)
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(
                subscriptionHistoryTracker: SubscriptionHistoryTracker()
            ))
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())
            .environment(\.selectedPackageId, nil)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        Self.pump(0.4)

        return window
    }

    /// `VideoPlayerView` renders through `PlayerLayerBackedView` when controls are hidden, so its
    /// presence in the UIKit tree is a direct read on whether a player exists.
    static func containsPlayerView(_ view: UIView) -> Bool {
        if view is PlayerLayerBackedView {
            return true
        }
        return view.subviews.contains { Self.containsPlayerView($0) }
    }

    static func tearDown(_ window: UIWindow) {
        window.rootViewController = nil
        window.resignKey()
        window.isHidden = true
    }

    static func pump(_ interval: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(interval))
    }

    /// Three full-bleed slides in flat colors, so the centre pixel identifies which one is showing.
    static func makeAutoAdvancingCarouselViewModel() throws -> CarouselComponentViewModel {
        let component = PaywallComponent.CarouselComponent(
            pages: [
                Self.makeSlide(hex: "#FF0000"),
                Self.makeSlide(hex: "#00FF00"),
                Self.makeSlide(hex: "#0000FF")
            ],
            pageSpacing: 0,
            // No peek, so the active slide fills the width and the centre pixel is unambiguous.
            pagePeek: 0,
            initialPageIndex: 0,
            loop: true,
            autoAdvance: .init(
                msTimePerPage: Self.msTimePerPage,
                msTransitionTime: Self.msTransitionTime,
                transitionType: .slide
            ),
            pageControl: nil
        )

        let factory = ViewModelFactory()
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: [],
            webCheckoutUrl: nil
        )

        guard case .carousel(let viewModel) = try factory.toViewModel(
            component: .carousel(component),
            packageValidator: factory.packageValidator,
            offering: offering,
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        ) else {
            throw XCTSkip("Expected a .carousel PaywallComponentViewModel")
        }

        return viewModel
    }

    static let slideColors: [PixelColor] = [
        .init(red: 255, green: 0, blue: 0),
        .init(red: 0, green: 255, blue: 0),
        .init(red: 0, green: 0, blue: 255)
    ]

    static func makeSlide(hex: String) -> PaywallComponent.StackComponent {
        return PaywallComponent.StackComponent(
            components: [],
            size: .init(width: .fill, height: .fixed(UInt(Self.windowSize.height))),
            backgroundColor: .init(light: .hex(hex))
        )
    }

    /// Pumps the run loop until the centre pixel differs from `color`, or the timeout expires.
    /// Returns whether it changed, so a caller can assert in either direction.
    static func slideChanges(
        from color: PixelColor,
        in window: UIWindow,
        within timeout: TimeInterval
    ) throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            Self.pump(0.05)
            if try Self.sampleSlideColor(window) != color {
                return true
            }
        }
        return false
    }

    static func sampleSlideColor(_ window: UIWindow) throws -> PixelColor {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        // `layer.render(in:)` rather than `drawHierarchy(in:afterScreenUpdates:)`: the latter needs
        // the window genuinely on screen and yields an all-black image under XCTest.
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }

        return try PixelSampler(image: image).color(
            column: Int(Self.windowSize.width / 2),
            row: Int(Self.windowSize.height / 2)
        )
    }

}

private struct PixelColor: Equatable, CustomStringConvertible {

    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var description: String {
        return String(format: "#%02X%02X%02X", self.red, self.green, self.blue)
    }

}

/// Reads the raw pixels of a rendered image so a single coordinate can be checked.
private struct PixelSampler {

    private let width: Int
    private let height: Int
    private let bytesPerRow: Int
    private let bytes: [UInt8]

    init(image: UIImage) throws {
        let cgImage = try XCTUnwrap(image.cgImage)
        self.width = cgImage.width
        self.height = cgImage.height
        self.bytesPerRow = cgImage.width * 4

        var buffer = [UInt8](repeating: 0, count: cgImage.width * 4 * cgImage.height)
        let context = try XCTUnwrap(
            CGContext(
                data: &buffer,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: cgImage.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(
            cgImage,
            in: .init(origin: .zero, size: .init(width: cgImage.width, height: cgImage.height))
        )
        self.bytes = buffer
    }

    func color(column: Int, row: Int) throws -> PixelColor {
        guard column >= 0, column < self.width, row >= 0, row < self.height else {
            throw XCTSkip("Pixel (\(column), \(row)) is outside the \(self.width)x\(self.height) render.")
        }

        let offset = row * self.bytesPerRow + column * 4
        return .init(
            red: self.bytes[offset],
            green: self.bytes[offset + 1],
            blue: self.bytes[offset + 2]
        )
    }

}

#endif
