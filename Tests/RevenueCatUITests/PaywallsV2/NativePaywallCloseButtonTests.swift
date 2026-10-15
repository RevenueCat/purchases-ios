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

    func testAutomaticDetectionReusesNavigationStack() async {
        if #available(iOS 16.0, *) {
            await self.assertNativeClose(expectedNavigationCount: 1) { button in
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
        var appearances = 0
        var disappearances = 0
        let host = UIHostingController(rootView:
            NavigationStack {
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Close", action: {},
                    content: { Button("Configured Close") {} }
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
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
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

    func testEmptyNativeHostPreservesCallerToolbarItems() async {
        for enabled in [false, true] {
            let host = UIHostingController(rootView: NavigationView {
                Text("Paywall").modifier(NativePaywallCloseHost(enabled: enabled))
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Caller") {} } }
            }.navigationViewStyle(.stack))
            let window = self.host(host)
            await self.waitForPresentation()
            let buttons = self.toolbarButtons(in: host.view)
            XCTAssertEqual(buttons.count, 1)
            XCTAssertTrue(buttons.contains { $0.accessibilityLabel == "Caller" })
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
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, expected ? 1 : 0, file: file, line: line)
    }

}

@MainActor
private final class NativeNavigationVisibilityTestState: ObservableObject {
    @Published var native = false
}

private struct NativeNavigationVisibilityTestView: View {
    @ObservedObject var state: NativeNavigationVisibilityTestState
    var body: some View {
        NativePaywallCloseButton(enabled: self.state.native, accessibilityLabel: "Close", action: {},
                                 content: { Text("Configured Close") })
    }
}

#endif
