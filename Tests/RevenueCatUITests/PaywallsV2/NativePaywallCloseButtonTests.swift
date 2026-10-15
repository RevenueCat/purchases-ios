//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class NativePaywallCloseButtonTests: NativePaywallNavigationTestCase {

    func testOwnedNativeNavigationDeliversPurchaseAndRestoreCallbacks() async throws {
        let data = PaywallComponentsData(
            templateName: "native-callbacks", assetBaseURL: URL(string: "https://example.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: [.button(.init(
                    action: .navigateBack,
                    stack: .init(components: [.text(.init(text: "close", color: .init(light: .hex("#000000"))))]),
                    useNativeIfPossible: true
                ))]), stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
            )),
            componentsLocalizations: ["en_US": ["close": .string("Close")]],
            revision: 1, defaultLocaleIdentifier: "en_US"
        )
        let offering = Offering(
            identifier: "native-callbacks", serverDescription: "",
            paywallComponents: .init(uiConfig: PreviewUIConfig.make(), data: data),
            availablePackages: [TestData.annualPackage], webCheckoutUrl: nil
        )
        let handler = PurchaseHandler.mock()
        let purchased = expectation(description: "Purchase callback crosses native navigation")
        let restored = expectation(description: "Restore callback crosses native navigation")
        let host = UIHostingController(rootView:
            PaywallView(configuration: .init(
                offering: offering, introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: handler
            ))
                .environment(\.nativePaywallNavigationContext, .standalone)
                .onPurchaseCompleted { info in
                    XCTAssertTrue(info === TestData.customerInfo)
                    purchased.fulfill()
                }
                .onRestoreCompleted { info in
                    XCTAssertTrue(info === TestData.customerInfo)
                    restored.fulfill()
                }
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(self.navigationCount(in: host), 1)
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
        _ = try await handler.purchase(package: TestData.annualPackage)
        await fulfillment(of: [purchased], timeout: 3)
        _ = try await handler.restorePurchases()
        handler.setRestored(TestData.customerInfo, success: true)
        await fulfillment(of: [restored], timeout: 3)
    }

    func testSwiftUINavigationContainersInstallNativeClose() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose { button in
                NavigationStack { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
            }
            await self.assertNativeClose { button in
                NavigationStack {
                    NavigationView { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
                        .navigationViewStyle(.stack)
                }
            }
            await self.assertNativeClose { button in
                NavigationView {
                    NavigationStack { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
                }.navigationViewStyle(.stack)
            }
        }
        await self.assertNativeClose { button in
            NavigationView { button.modifier(NativePaywallCloseHost()).navigationTitle("Paywall") }
                .navigationViewStyle(.stack)
        }
    }

    func testWithoutNativeCloseHostKeepsFallback() async {
        await self.assertNativeClose(expected: false) { button in button }
    }

    func testAutomaticDetectionDoesNotAllocateAnExtraToolbarItem() async throws {
        var referenceImages: [Int: UIImage] = [:]
        var toolbarBand: CGRect?
        for automatic in [false, true] {
            let state = NativeNavigationVisibilityTestState()
            let content = NativeNavigationVisibilityTestView(state: state)
            let presented = automatic
                ? AnyView(content.modifier(NativePaywallNavigationModifier(requested: true)))
                : AnyView(content.modifier(NativePaywallCloseHost()))
            let host = UIHostingController(rootView: NavigationView {
                presented.navigationTitle("Paywall").toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {} label: { Image(systemName: "questionmark.circle") }
                            .accessibilityLabel("Help")
                    }
                }
            }.navigationViewStyle(.stack))
            let window = self.host(host)
            defer { self.close(window) }
            for (phase, native) in [false, true, false].enumerated() {
                state.native = native
                await self.waitForPresentation()
                XCTAssertFalse(try XCTUnwrap(self.navigationController(in: host)).isNavigationBarHidden)
                XCTAssertEqual(state.available, native)
                if !automatic {
                    let buttons = self.toolbarButtons(in: host.view)
                    XCTAssertEqual(buttons.count, native ? 1 : 0)
                    if let close = buttons.first {
                        let frame = close.convert(close.bounds, to: window)
                        toolbarBand = CGRect(x: 0, y: frame.minY - 4,
                                             width: window.bounds.width, height: frame.height + 8)
                    }
                }
                let bounds = CGRect(x: 0, y: 0, width: window.bounds.width, height: 200)
                let screenshot = UIGraphicsImageRenderer(bounds: bounds).image { _ in
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                }
                let attachment = XCTAttachment(image: screenshot)
                attachment.name = "Automatic \(automatic), native \(native), phase \(phase)"
                attachment.lifetime = .keepAlways
                self.add(attachment)
                if automatic {
                    let band = try XCTUnwrap(toolbarBand)
                    let expected = try self.toolbarIconCenters(in: XCTUnwrap(referenceImages[phase]), band: band)
                    let actual = try self.toolbarIconCenters(in: screenshot, band: band)
                    XCTAssertEqual(expected.count, native ? 2 : 1)
                    XCTAssertEqual(actual.count, expected.count)
                    for (reference, rendered) in zip(expected, actual) {
                        XCTAssertEqual(rendered, reference, accuracy: Double(screenshot.scale),
                                       "Detection must not displace toolbar content")
                    }
                } else {
                    referenceImages[phase] = screenshot
                }
            }
        }
    }

    // Compare icon positions without depending on whether the OS shares or separates glass backgrounds.
    private func toolbarIconCenters(in image: UIImage, band: CGRect) throws -> [Double] {
        let crop = CGRect(x: band.minX * image.scale, y: band.minY * image.scale,
                          width: band.width * image.scale, height: band.height * image.scale)
        let cgImage = try XCTUnwrap(image.cgImage?.cropping(to: crop))
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(
                data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }
        var centers: [Double] = []
        var start: Int?
        for column in 0...width {
            let hasInk = column < width && (0..<height).contains { row in
                let offset = (row * width + column) * 4
                return pixels[offset] < 64 && pixels[offset + 1] < 64 && pixels[offset + 2] < 64
                    && pixels[offset + 3] > 128
            }
            if hasInk, start == nil { start = column }
            if !hasInk, let first = start {
                centers.append(Double(first + column - 1) / 2)
                start = nil
            }
        }
        return centers
    }

    func testAutomaticDetectionReusesNavigationStack() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose(expectedNavigationCount: 1, verifyUIKitControl: false) { button in
                NavigationStack {
                    button.modifier(NativePaywallNavigationModifier(requested: true)).navigationTitle("Paywall")
                }
            }
        }
    }

    func testConfigurationRequestsPreflightOnlyForNativeCloseActions() {
        func requested(native: Bool, visible: Bool? = nil, action: PaywallComponent.ButtonComponent.Action) -> Bool {
            let config = PaywallComponentsData.ComponentsConfig(base: .init(
                stack: .init(components: [.stack(.init(components: [.button(.init(
                    visible: visible, action: action, stack: .init(components: []), useNativeIfPossible: native
                ))]))]),
                stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
            ))
            let data = PaywallComponentsData(
                templateName: "components", assetBaseURL: URL(string: "https://example.com")!,
                componentsConfig: config, componentsLocalizations: ["en_US": [:]],
                revision: 0, defaultLocaleIdentifier: "en_US"
            )
            return NativePaywallNavigationModifier(
                paywallComponents: .init(uiConfig: PreviewUIConfig.make(), data: data),
                workflowContext: nil
            ).requested
        }
        XCTAssertTrue(requested(native: true, action: .navigateBack))
        XCTAssertFalse(requested(native: false, action: .navigateBack))
        XCTAssertFalse(requested(native: true, visible: false, action: .navigateBack))
        XCTAssertFalse(requested(native: true, action: .restorePurchases))
    }

    func testUnknownHostRetainsConfiguredCloseWithoutAddingNavigation() async {
        await self.assertNativeClose(expected: false, expectedNavigationCount: 0) { button in
            button.modifier(NativePaywallNavigationModifier(requested: true))
        }
    }

    func testOwnedPresentationInstallsExactlyOneNavigationContainer() async {
        await self.assertNativeClose(expectedNavigationCount: 1) { button in
            button.modifier(NativePaywallNavigationModifier(requested: true))
                .environment(\.nativePaywallNavigationContext, .standalone)
        }
    }

    func testDetectingExistingNavigationDoesNotRemountPaywallContent() async {
        guard #available(iOS 16.0, *) else { return }
        var available = false
        var appearances = 0
        var disappearances = 0
        let host = UIHostingController(rootView:
            NavigationStack {
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Close", action: {},
                    content: { Button("Configured Close") {} }, availabilityChanged: { available = $0 }
                )
                .onAppear { appearances += 1 }
                .onDisappear { disappearances += 1 }
                .modifier(NativePaywallNavigationModifier(requested: true))
            }
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(appearances, 1)
        XCTAssertEqual(disappearances, 0)
        XCTAssertEqual(self.navigationCount(in: host), 1)
        XCTAssertTrue(available)
    }

    func testOwnedNavigationHidesUnusedBarAcrossNativeOverrides() async throws {
        let state = NativeNavigationVisibilityTestState()
        let host = UIHostingController(rootView: NativeNavigationVisibilityTestView(state: state)
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .standalone))
        let window = self.host(host)
        defer { self.close(window) }
        for enabled in [false, true, false] {
            state.native = enabled
            await self.waitForPresentation()
            let navigation = try XCTUnwrap(self.navigationController(in: host))
            XCTAssertEqual(navigation.isNavigationBarHidden, !enabled)
            XCTAssertEqual(self.navigationCount(in: host), 1)
            XCTAssertEqual(self.toolbarButtons(in: host.view).count, enabled ? 1 : 0)
        }
    }

    func testEmptyNativeHostPreservesCallerToolbarItems() async throws {
        for enabled in [nil, false, true] as [Bool?] {
            var callerAppeared = false
            let content = enabled.map { AnyView(Text("Paywall").modifier(NativePaywallCloseHost(enabled: $0))) }
                ?? AnyView(Text("Paywall"))
            let host = UIHostingController(rootView: NavigationView {
                content.navigationTitle("Paywall")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {} label: { Image(systemName: "questionmark.circle") }
                                .accessibilityLabel("Caller")
                                .onAppear { callerAppeared = true }
                        }
                    }
            }.navigationViewStyle(.stack))
            let window = self.host(host)
            await self.waitForPresentation()
            XCTAssertTrue(callerAppeared, "Caller item must appear with and without an empty native host")
            XCTAssertFalse(try XCTUnwrap(self.navigationController(in: host)).isNavigationBarHidden)
            let screenshot = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "Caller toolbar with native host \(String(describing: enabled))"
            attachment.lifetime = .keepAlways
            self.add(attachment)
            self.close(window)
        }
    }

    func testHiddenNavigationBarKeepsConfiguredClose() async {
        guard #available(iOS 16.0, *) else { return }
        await self.assertNativeClose(expected: false, expectedNavigationCount: 1) { button in
            NavigationStack {
                button.modifier(NativePaywallNavigationModifier(requested: true))
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private func assertNativeClose<Content: View>(
        expected: Bool = true,
        expectedNavigationCount: Int? = nil,
        verifyUIKitControl: Bool = true,
        @ViewBuilder container: (NativePaywallCloseButton<Button<Text>>) -> Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        var available = false
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: { available = $0 }
        )
        let host = UIHostingController(rootView: container(button))
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(available, expected, file: file, line: line)
        if let expectedNavigationCount {
            XCTAssertEqual(self.navigationCount(in: host), expectedNavigationCount, file: file, line: line)
        }
        if verifyUIKitControl {
            XCTAssertEqual(self.toolbarButtons(in: host.view).count, expected ? 1 : 0, file: file, line: line)
        }
    }

}

@MainActor
private final class NativeNavigationVisibilityTestState: ObservableObject {
    @Published var native = false
    var available = false
}

@available(iOS 15.0, *)
private struct NativeNavigationVisibilityTestView: View {
    @ObservedObject var state: NativeNavigationVisibilityTestState
    var body: some View {
        NativePaywallCloseButton(enabled: self.state.native, accessibilityLabel: "Close", action: {},
                                 content: { Text("Configured Close") },
                                 availabilityChanged: { self.state.available = $0 })
    }
}

#endif
