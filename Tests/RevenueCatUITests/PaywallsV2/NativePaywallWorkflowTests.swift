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
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
@MainActor
final class NativePaywallWorkflowTests: NativePaywallNavigationTestCase {

    func testFullScreenPresentationAddsMissingNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: true, existingNavigation: false, style: .fullScreen)
    }

    func testSheetPresentationAddsMissingNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: true, existingNavigation: false, style: .pageSheet)
    }

    func testFullScreenPresentationReusesExistingNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: true, existingNavigation: true, style: .fullScreen)
    }

    func testNativeCloseDisabledDoesNotAddNavigation() async throws {
        try self.requireAppHost()
        await self.assertModalNativeClose(enabled: false, existingNavigation: false, style: .fullScreen)
    }

    func testNoEligibleCloseDoesNotCreateEmptyToolbarButton() async {
        let host = UIHostingController(rootView:
            Text("Paywall without a close button")
                .modifier(NativePaywallNavigationModifier(requested: true))
                .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 0)
    }

    func testMultipleEligibleCloseComponentsCreateOnlyOneNativeButton() async {
        var configuredAppearances = 0
        let host = UIHostingController(rootView:
            VStack {
                ForEach(0..<2) { index in
                    NativePaywallCloseButton(
                        enabled: true, accessibilityLabel: "Close \(index)", action: {},
                        content: { Button("Configured Close") {}.onAppear { configuredAppearances += 1 } }
                    )
                }
            }
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
        XCTAssertEqual(configuredAppearances, 0)
        XCTAssertEqual(self.navigationCount(in: host), 1)
    }

    func testReturningToBackOnlyOrButtonlessPageRemovesNativeCloseFromToolbar() async {
        let state = NativeScopedWorkflowTestState()
        let host = UIHostingController(rootView:
            NativeScopedWorkflowTestView(state: state)
                .modifier(NativePaywallNavigationModifier(requested: true))
                .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }

        for page in [0, 2, 1, 0, 2, 1] {
            state.page = page
            await self.waitForPresentation()
            XCTAssertEqual(self.toolbarButtons(in: host.view).count, page == 2 ? 1 : 0,
                           "Close must belong only to the page that actually configures it")
        }
    }

    func testThirdPageHeaderAndBodyButtonsShareNativeSlotsWithoutDesignedDuplicates() async {
        let state = NativeThreePageTestState()
        let coordinator = NativePaywallCloseCoordinator()
        var configuredAppearances = 0
        let host = UIHostingController(rootView:
            NativeThreePageTestView(state: state, configuredAppeared: { configuredAppearances += 1 })
                .environment(\.nativePaywallCloseCoordinator, coordinator)
        )
        let window = self.host(host)
        defer { self.close(window) }

        for page in [0, 1, 2, 1, 2, 0] {
            state.page = page
            await self.waitForPresentation()
            XCTAssertEqual(coordinator.actions.count, page == 2 ? 4 : 2)
            XCTAssertEqual(coordinator.action(for: .back) != nil, page > 0)
            XCTAssertTrue(coordinator.action(for: .close)?.isWorkflowClose == true)
            XCTAssertEqual(configuredAppearances, 0, "Active pages must not show opted-in header or body buttons")
        }
    }

    func testReturningToRootDoesNotRestoreDesignedBackOrRegisterTransitionCopies() async {
        let state = NativeWorkflowHeaderTestState()
        let coordinator = NativePaywallCloseCoordinator()
        var configuredAppearances = 0
        let host = UIHostingController(rootView:
            NativeWorkflowHeaderTestView(state: state, configuredAppeared: { configuredAppearances += 1 })
                .environment(\.nativePaywallCloseCoordinator, coordinator)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertEqual(coordinator.actions.count, 2)
        XCTAssertNil(coordinator.action(for: .back))
        XCTAssertTrue(coordinator.action(for: .close)?.isWorkflowClose == true)
        XCTAssertEqual(configuredAppearances, 0)

        for canNavigateBack in [true, false, true, false] {
            state.canNavigateBack = canNavigateBack
            state.showsTransitionCopy = true
            await self.waitForPresentation()
            XCTAssertEqual(coordinator.actions.count, 2, "The animated header must not register copies")
            XCTAssertEqual(coordinator.action(for: .back) != nil, canNavigateBack)
            XCTAssertEqual(configuredAppearances, 0)
            state.showsTransitionCopy = false
            await self.waitForPresentation()
            XCTAssertEqual(coordinator.actions.count, 2)
            XCTAssertEqual(configuredAppearances, 0, "Returning to root must not restore the redundant Back")
        }
    }

    func testSwiftUIHeaderShowsSeparateNativeBackAndClose() async {
        var backRegistered = false
        var closeRegistered = false
        let host = UIHostingController(rootView:
            VStack {
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Back", role: .back, action: {},
                    content: { Button("Designed Back") {} },
                    availabilityChanged: { backRegistered = $0 }
                )
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                    content: { Button("Designed Close") {} },
                    availabilityChanged: { closeRegistered = $0 }
                )
            }
            .modifier(NativePaywallNavigationModifier(requested: true))
            .environment(\.nativePaywallNavigationContext, .standalone)
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        self.commitFrame(window)
        XCTAssertTrue(backRegistered)
        XCTAssertTrue(closeRegistered)
        // SwiftUI's Back is hosted content, not a UIButton. Close and any automatic host Back
        // are UIKit buttons. There should only be the single native Close here.
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
        XCTAssertEqual(self.navigationCount(in: host), 1)
    }

    func testPushedWorkflowBackDoesNotDuplicateHostBack() async throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("NavigationStack requires iOS 16") }
        var backRegistered = false
        var closeRegistered = false
        let host = UIHostingController(rootView:
            NavigationStack(path: .constant([1])) {
                Text("Account")
                    .navigationDestination(for: Int.self) { _ in
                        VStack {
                            NativePaywallCloseButton(
                                enabled: true, accessibilityLabel: "Back", role: .back, action: {},
                                content: { Button("Designed Back") {} },
                                availabilityChanged: { backRegistered = $0 }
                            )
                            NativePaywallCloseButton(
                                enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                                content: { Button("Designed Close") {} },
                                availabilityChanged: { closeRegistered = $0 }
                            )
                        }
                        .modifier(NativePaywallCloseHost())
                        .navigationTitle("Upgrade")
                    }
            }
        )
        let window = self.host(host)
        defer { self.close(window) }
        await self.waitForPresentation()
        self.commitFrame(window)
        XCTAssertTrue(backRegistered)
        XCTAssertTrue(closeRegistered)
        // SwiftUI's Back is hosted content, not a UIButton. Close and any automatic host Back
        // are UIKit buttons. There should only be the single native Close here.
        XCTAssertEqual(self.toolbarButtons(in: host.view).count, 1)
    }

    func testUnownedFullScreenCoverRetainsFallbackWithoutAddingNavigation() async throws {
        try self.requireAppHost()
        var available = false
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: { available = $0 }
        )
        let presenter = UIHostingController(rootView:
            Color.clear.fullScreenCover(isPresented: .constant(true)) {
                button.modifier(NativePaywallNavigationModifier(requested: true))
            }
        )
        let window = self.host(presenter)
        defer { self.close(window) }
        await self.waitForPresentation()
        XCTAssertNotNil(presenter.presentedViewController)
        XCTAssertFalse(available)
        XCTAssertEqual(self.navigationCount(in: presenter.presentedViewController), 0)
    }

    private func assertModalNativeClose(
        enabled: Bool,
        existingNavigation: Bool,
        style: UIModalPresentationStyle,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        var available = false
        var reportedInstalled = false
        let installed = enabled ? expectation(description: "Native close visible") : nil
        let button = NativePaywallCloseButton(
            enabled: enabled, accessibilityLabel: "Close", action: {},
            content: { Button("Configured Close") {} }, availabilityChanged: {
                available = $0
                if $0 && !reportedInstalled {
                    reportedInstalled = true
                    installed?.fulfill()
                }
            }
        )
        let owner = NativePaywallUIKitOwner()
        let host = UIHostingController(rootView:
            VStack {
                Text("Sample paywall")
                button
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(NativePaywallNavigationModifier(requested: enabled))
            .environment(\.nativePaywallNavigationContext, existingNavigation ? .uiKit(owner) : .standalone)
        )
        let modal: UIViewController = existingNavigation ? UINavigationController(rootViewController: host) : host
        owner.prepare(controller: host)
        modal.modalPresentationStyle = style
        // Navigation in the presenter must not be mistaken for navigation in its modal.
        let presenter = UINavigationController(rootViewController: UIViewController())
        let window = self.host(presenter)
        defer { self.close(window) }
        await self.waitForPresentation()
        presenter.present(modal, animated: false)
        if let installed { await fulfillment(of: [installed], timeout: 3) }
        await self.waitForPresentation()
        XCTAssertTrue(presenter.presentedViewController === modal, file: file, line: line)
        XCTAssertEqual(available, enabled, file: file, line: line)
        XCTAssertEqual(self.navigationCount(in: modal), enabled ? 1 : 0, file: file, line: line)
        XCTAssertEqual(self.toolbarButtons(in: modal.view).count, enabled ? 1 : 0, file: file, line: line)
        modal.dismiss(animated: false)
        await self.waitForPresentation()
        XCTAssertNil(presenter.presentedViewController, file: file, line: line)
    }

    private func commitFrame(_ window: UIWindow) {
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Workflow native navigation"
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    private func requireAppHost() throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty,
                      "Generate with TUIST_UI_TESTS_HOST_APP=true to test actual modal presentations.")
    }

}

@available(iOS 15.0, *)
@MainActor
private final class NativeWorkflowHeaderTestState: ObservableObject {
    @Published var canNavigateBack = false
    @Published var showsTransitionCopy = false
}

@available(iOS 15.0, *)
private struct NativeWorkflowHeaderTestView: View {
    @ObservedObject var state: NativeWorkflowHeaderTestState
    let configuredAppeared: () -> Void

    var body: some View {
        VStack {
            self.header
            if self.state.showsTransitionCopy {
                self.header.environment(\.nativePaywallButtonRegistrationEnabled, false)
            }
        }
    }

    private var header: some View {
        HStack {
            NativePaywallCloseButton(
                enabled: true, accessibilityLabel: "Back",
                role: self.state.canNavigateBack ? .back : .close, action: {},
                content: { Text("Designed Back").onAppear(perform: self.configuredAppeared) }
            )
            NativePaywallCloseButton(
                enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                content: { Text("Designed Close").onAppear(perform: self.configuredAppeared) }
            )
        }
    }
}

@available(iOS 15.0, *)
@MainActor
private final class NativeThreePageTestState: ObservableObject {
    @Published var page = 0
}

@available(iOS 15.0, *)
private struct NativeThreePageTestView: View {
    @ObservedObject var state: NativeThreePageTestState
    let configuredAppeared: () -> Void

    var body: some View {
        ZStack {
            ForEach(0..<3) { page in
                VStack {
                    self.buttons(page: page)
                    if page == 2 {
                        self.buttons(page: page)
                    }
                }
                .environment(\.nativePaywallCloseEnabled, self.state.page == page)
                .opacity(self.state.page == page ? 1 : 0)
            }
        }
    }

    private func buttons(page: Int) -> some View {
        HStack {
            NativePaywallCloseButton(
                enabled: self.state.page == page, accessibilityLabel: "Back",
                role: self.state.page > 0 ? .back : .close, action: {},
                content: { self.designedButton(page: page) }
            )
            NativePaywallCloseButton(
                enabled: self.state.page == page, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                content: { self.designedButton(page: page) }
            )
        }
    }

    private func designedButton(page: Int) -> some View {
        Text("Designed button").onAppear {
            if self.state.page == page { self.configuredAppeared() }
        }
    }
}

@available(iOS 15.0, *)
@MainActor
private final class NativeScopedWorkflowTestState: ObservableObject {
    let pageIDs = [UUID(), UUID(), UUID()]
    @Published var page = 0
}

@available(iOS 15.0, *)
private struct NativeScopedWorkflowTestView: View {
    @ObservedObject var state: NativeScopedWorkflowTestState
    @Environment(\.nativePaywallCloseCoordinator) private var coordinator

    var body: some View {
        ZStack {
            ForEach(0..<3) { page in
                VStack {
                    Text("Page \(page)")
                    if page > 0 {
                        NativePaywallCloseButton(
                            enabled: true, accessibilityLabel: "Back", role: .back, action: {},
                            content: { Text("Designed Back") }
                        )
                    }
                    if page == 2 {
                        NativePaywallCloseButton(
                            enabled: true, accessibilityLabel: "Close", isWorkflowClose: true, action: {},
                            content: { Text("Designed Close") }
                        )
                    }
                }
                .environment(\.nativePaywallPageID, self.state.pageIDs[page])
                .opacity(self.state.page == page ? 1 : 0)
            }
        }
        .onAppear { self.coordinator?.activatePage(self.state.pageIDs[self.state.page]) }
        .onChange(of: self.state.page) { page in self.coordinator?.activatePage(self.state.pageIDs[page]) }
    }
}

#endif
