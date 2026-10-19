//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentViewTests.swift
//
//  Created by RevenueCat on 5/19/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class ButtonComponentViewTests: TestCase {

    func testInlineSheetDisablesNativeActionsWithoutRemovingTheirNavigationSlots() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: "inline", name: "Inline sheet", stack: .init(components: []),
            backgroundBlur: false, size: .init(width: .fill, height: .fixed(100))
        )
        let sheetStack = try Self.makeViewModel(
            component: .init(action: .navigateBack, stack: sheet.stack)
        ).stackViewModel
        let view = NativeInlineSheetRegistrationTestView(
            state: state, sheet: .init(sheet: sheet, sheetStackViewModel: sheetStack)
        )
        .environment(\.nativePaywallCloseCoordinator, coordinator)
        .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
        .environmentObject(IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker))
        .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 2 && coordinator.actions.allSatisfy(\.isEnabled)
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        let originalIDs = Set(coordinator.actions.map(\.id))

        state.value = 2
        let suspended = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 2 && coordinator.actions.allSatisfy { !$0.isEnabled }
        }, object: nil)
        await fulfillment(of: [suspended], timeout: 2)
        XCTAssertEqual(Set(coordinator.actions.map(\.id)), originalIDs,
                       "The sheet must not restore the caller's Back or change the outer layout")
        let backID = try XCTUnwrap(coordinator.action(for: .back)?.id)
        try await coordinator.performAction(id: backID)
        XCTAssertEqual(state.performed, 0)

        state.value = 1
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 2 && coordinator.actions.allSatisfy(\.isEnabled)
        }, object: nil)
        await fulfillment(of: [restored], timeout: 2)
        XCTAssertEqual(Set(coordinator.actions.map(\.id)), originalIDs)
        try await coordinator.performAction(id: backID)
        XCTAssertEqual(state.performed, 1)

        state.showsButton = false
        let ancestorDisabled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 2 && coordinator.actions.allSatisfy { !$0.isEnabled }
        }, object: nil)
        await fulfillment(of: [ancestorDisabled], timeout: 2)
        for value in [2, 1] {
            state.value = value
            let unexpectedlyEnabled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                coordinator.actions.contains(where: \.isEnabled)
            }, object: nil)
            unexpectedlyEnabled.isInverted = true
            await fulfillment(of: [unexpectedlyEnabled], timeout: 0.3)
            XCTAssertEqual(Set(coordinator.actions.map(\.id)), originalIDs)
            try await coordinator.performAction(id: backID)
            XCTAssertEqual(state.performed, 1, "Closing a sheet must preserve an ancestor's disabled state")
        }
    }

    func testRenderedCarouselsOnlyPublishTheInitialActiveSlidesAction() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        for loops in [false, true] {
            let pages: [PaywallComponent.StackComponent] = (0..<3).map { index in
                .init(components: [.button(.init(
                    id: "slide-\(index)", action: .navigateBack,
                    stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
                ))], size: .init(width: .fill, height: .fixed(100)))
            }
            let data = PaywallComponentsData(
                templateName: "native-carousel", assetBaseURL: URL(string: "https://example.com")!,
                componentsConfig: .init(base: .init(
                    stack: .init(components: [.carousel(.init(pages: pages, initialPageIndex: 1, loop: loops))]),
                    stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
                )),
                componentsLocalizations: ["en_US": ["Close": .string("Close")]],
                revision: 1, defaultLocaleIdentifier: "en_US"
            )
            let components = Offering.PaywallComponents(uiConfig: PreviewUIConfig.make(), data: data)
            let offering = Offering(identifier: "native-carousel", serverDescription: "", paywallComponents: components,
                                    availablePackages: [TestData.annualPackage], webCheckoutUrl: nil)
            let coordinator = NativePaywallCloseCoordinator()
            var triggered: [String] = []
            let view = PaywallsV2View(
                paywallComponents: components, offering: offering, purchaseHandler: .mock(),
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker, showZeroDecimalPlacePrices: false,
                onDismiss: {}, failedToLoadFont: { _ in }, colorScheme: .light
            )
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environment(\.workflowTriggerAction, { triggered.append($0); return true })
            let (window, _) = Self.host(view)
            defer { window.isHidden = true; window.rootViewController = nil }
            let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                coordinator.actions.count == 1
            }, object: nil)
            await fulfillment(of: [registered], timeout: 2)
            try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
            XCTAssertEqual(triggered, ["slide-1"], "Only the visible original or loop copy may supply the callback")
        }
    }

    func testOnlyActiveCarouselPageRegistersAcrossLoopCopiesAndNestedCarousels() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        let (window, _) = Self.host(NativeCarouselRegistrationTestView(state: state)
            .environment(\.nativePaywallCloseCoordinator, coordinator))
        defer { window.isHidden = true; window.rootViewController = nil }
        for activeIndex in [1, 2, 4] {
            state.value = activeIndex
            let active = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                coordinator.actions.count == 1 && coordinator.actions.first?.label == "Slide \(activeIndex)"
            }, object: nil)
            await fulfillment(of: [active], timeout: 2)
            try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
            XCTAssertEqual(state.performed, activeIndex)
        }
        state.showsButton = false
        let inactiveAncestor = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.isEmpty
        }, object: nil)
        await fulfillment(of: [inactiveAncestor], timeout: 2)
        state.showsButton = true
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1 && coordinator.actions.first?.label == "Slide 4"
        }, object: nil)
        await fulfillment(of: [restored], timeout: 2)
    }

    func testNativeRegistrationRefreshesCallbackAndUnregistersWhenRemoved() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        var height: CGFloat = 0
        let view = NativeRegistrationTestView(state: state)
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        state.value = 2
        let updated = expectation(description: "Callback view updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { updated.fulfill() }
        await fulfillment(of: [updated], timeout: 2)
        try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
        XCTAssertEqual(state.performed, 2, "Callback changes must reach an already registered action")
        XCTAssertEqual(height, 88, accuracy: 0.5, "The registration primitive has zero size")
        state.showsButton = false
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.isEmpty
        }, object: nil)
        await fulfillment(of: [removed], timeout: 2)
    }

    func testInactiveWorkflowPageKeepsNativeHeaderCollapsedWithoutRegisteringActions() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let button = PaywallComponent.ButtonComponent(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        )
        let data = PaywallComponentsData(
            templateName: "native-header", assetBaseURL: URL(string: "https://example.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(components: []),
                header: .init(stack: .init(
                    components: [.button(button)], size: .init(width: .fill, height: .fixed(100))
                )),
                stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
            )),
            componentsLocalizations: ["en_US": ["Close": .string("Close")]],
            revision: 1, defaultLocaleIdentifier: "en_US"
        )
        let components = Offering.PaywallComponents(uiConfig: PreviewUIConfig.make(), data: data)
        let offering = Offering(identifier: "native-header", serverDescription: "", paywallComponents: components,
                                availablePackages: [TestData.annualPackage], webCheckoutUrl: nil)
        let coordinator = NativePaywallCloseCoordinator()
        var hiddenButtons = 0
        let view = PaywallsV2View(
            paywallComponents: components, offering: offering, purchaseHandler: .mock(),
            introEligibilityChecker: BaseSnapshotTest.eligibleChecker, showZeroDecimalPlacePrices: false,
            onDismiss: {}, failedToLoadFont: { _ in }, colorScheme: .light, isActiveWorkflowPage: false
        )
        .environment(\.nativePaywallCloseCoordinator, coordinator)
        .onPreferenceChange(NativePaywallHiddenButtonsKey.self) { hiddenButtons = $0.count }
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let settled = expectation(description: "Inactive page layout settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
        XCTAssertEqual(hiddenButtons, 1, "Inactive native buttons must remain placeholders")
        XCTAssertTrue(coordinator.actions.isEmpty, "Inactive pages must not own native toolbar actions")
    }

    func testRegisteredNativeButtonRunsItsActionWithoutMountingFallback() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let coordinator = NativePaywallCloseCoordinator()
        var actions = 0
        var fallbackAppearances = 0
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: { actions += 1 },
            content: { Button("Configured Close") {}.onAppear { fallbackAppearances += 1 } }
        )
        .environment(\.nativePaywallCloseCoordinator, coordinator)
        let (window, _) = Self.host(button)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
        XCTAssertEqual(actions, 1)
        XCTAssertEqual(fallbackAppearances, 0)
    }

    func testNativeButtonsDoNotLeaveFlexStackSpacers() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let markers: [PaywallComponent] = ["#FF0000", "#0000FF"].map { color in
            .stack(.init(components: [], size: .init(width: .fixed(20), height: .fixed(20)),
                         backgroundColor: .init(light: .hex(color))))
        }
        let button = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        for distribution: PaywallComponent.FlexDistribution in [.spaceBetween, .spaceAround, .spaceEvenly] {
            for dimension: PaywallComponent.Dimension in [
                .vertical(.center, distribution), .horizontal(.center, distribution)
            ] {
                func stack(_ children: [PaywallComponent]) -> PaywallComponent.StackComponent {
                    .init(components: children, dimension: dimension,
                          size: .init(width: .fixed(200), height: .fixed(200)), spacing: 24)
                }
                let reference = try await self.renderNativeStack(stack(markers), actions: 0)
                let native = try await self.renderNativeStack(stack([markers[0], button, markers[1]]), actions: 1)
                let empty = try await self.renderNativeStack(stack([]), actions: 0)
                XCTAssertNotEqual(reference.pngData(), empty.pngData(), "Markers must actually render")
                XCTAssertEqual(native.pngData(), reference.pngData(), "Native children must not affect flex spacing")
            }
        }
    }

    private func renderNativeStack(_ stack: PaywallComponent.StackComponent, actions: Int) async throws -> UIImage {
        let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        let view = StackComponentView(viewModel: model, onDismiss: {})
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        let (window, hosted) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == actions
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        let settled = expectation(description: "Flex layout settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        await fulfillment(of: [settled], timeout: 2)
        window.layoutIfNeeded()
        hosted.layoutIfNeeded()
        return UIGraphicsImageRenderer(bounds: hosted.bounds).image { _ in
            hosted.drawHierarchy(in: hosted.bounds, afterScreenUpdates: true)
        }
    }

    func testNestedNativeOnlyWrappersDoNotLeaveSpacingInNormalOrFlexStacks() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let markers: [PaywallComponent] = ["#FF0000", "#0000FF"].map { color in
            .stack(.init(components: [], size: .init(width: .fixed(20), height: .fixed(20)),
                         backgroundColor: .init(light: .hex(color))))
        }
        let button = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        let secondary = PaywallComponent.button(.init(
            visible: false, action: .navigateBack, stack: Self.makeButtonStack(label: "Close")
        ))
        let hiddenStack = PaywallComponent.stack(.init(visible: false, components: [.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close")
        ))]))
        let wrappers = [[button], [button, secondary], [button, hiddenStack]].map { children in
            PaywallComponent.stack(.init(components: [.stack(.init(
                components: children, size: .init(width: .fixed(80), height: .fixed(80)),
                padding: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
            ))], size: .init(width: .fixed(100), height: .fixed(100))))
        }
        for distribution: PaywallComponent.FlexDistribution in [.start, .spaceBetween, .spaceAround, .spaceEvenly] {
            for dimension: PaywallComponent.Dimension in [
                .vertical(.center, distribution), .horizontal(.center, distribution)
            ] {
                func stack(_ children: [PaywallComponent]) -> PaywallComponent.StackComponent {
                    .init(components: children, dimension: dimension,
                          size: .init(width: .fixed(200), height: .fixed(200)), spacing: 12)
                }
                let reference = try await self.renderNativeStack(stack(markers), actions: 0)
                for wrapper in wrappers {
                    let nested = try await self.renderNativeStack(stack([markers[0], wrapper, markers[1]]), actions: 1)
                    XCTAssertEqual(nested.pngData(), reference.pngData(),
                                   "Empty wrappers must not consume layout space")
                }
            }
        }
    }

    func testNativeWrapperTracksHiddenSecondaryButtonWithoutRemountingRegistration() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let close = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        let secondary = PaywallComponent.button(.init(
            visible: false, action: .navigateBack, stack: Self.makeButtonStack(label: "Close"),
            overrides: [.init(conditions: [.selected], properties: .init(visible: true))]
        ))
        let wrapper = PaywallComponent.stack(.init(
            components: [close, secondary], size: .init(width: .fill, height: .fixed(80))
        ))
        let model = try StackComponentViewModel(component: .init(components: [wrapper]), localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        var height: CGFloat = -1
        let content = StackComponentView(viewModel: model, onDismiss: {})
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { proxy in
                Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
            })
            .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
        let (window, _) = Self.host(Self.nativeLayoutEnvironment(
            NativeHeaderVisibilityTestView(state: state, content: content), coordinator: coordinator
        ))
        defer { window.isHidden = true; window.rootViewController = nil }
        var actionID: UUID?
        for (value, expected): (Int, CGFloat) in [(1, 0), (2, 80), (1, 0)] {
            state.value = value
            let settled = expectation(description: "Secondary button visibility settles")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
            await fulfillment(of: [settled], timeout: 2)
            XCTAssertEqual(height, expected, accuracy: 0.5, "selected=\(value)")
            XCTAssertEqual(coordinator.actions.count, 1)
            let currentID = try XCTUnwrap(coordinator.actions.first?.id)
            if let actionID { XCTAssertEqual(currentID, actionID, "Visibility must not remount native registration") }
            actionID = currentID
        }
    }

    func testNativeHeaderRestoresSafeAreaWhenBodyHeroIsHidden() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let imageURL = try Self.makeHeroImageURL()
        defer { try? FileManager.default.removeItem(at: imageURL) }
        let image = PaywallComponent.image(.init(
            source: .init(light: .init(
                width: 1, height: 1, original: imageURL, heic: imageURL, heicLowRes: imageURL
            )),
            size: .init(width: .fill, height: .fixed(60)),
            overrides: [.init(conditions: [.selected], properties: .init(visible: false))]
        ))
        let close = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        let config = PaywallComponentsData.PaywallComponentsConfig(
            stack: .init(components: [image, .stack(.init(
                components: [], size: .init(width: .fill, height: .fixed(20)),
                backgroundColor: .init(light: .hex("#FF0000"))
            ))], spacing: 0),
            header: .init(stack: .init(components: [close])), stickyFooter: nil,
            background: .color(.init(light: .hex("#FFFFFF")))
        )
        var factory = ViewModelFactory()
        let root = try factory.toRootViewModel(
            componentsConfig: config,
            offering: .init(identifier: "native-layout", serverDescription: "", availablePackages: [],
                            webCheckoutUrl: nil),
            localizationProvider: .init(locale: Locale(identifier: "en_US"),
                                        localizedStrings: ["Close": .string("Close")]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()), colorScheme: .light
        )
        let state = NativeRegistrationTestState()
        let coordinator = NativePaywallCloseCoordinator()
        let (window, hosted) = Self.host(Self.nativeLayoutEnvironment(
            NativeHeaderVisibilityTestView(
                state: state, content: RootView(viewModel: root, onDismiss: {}, defaultPackage: nil)
            ), coordinator: coordinator, safeAreaInsets: .init(top: 88, leading: 0, bottom: 0, trailing: 0)
        ))
        defer { window.isHidden = true; window.rootViewController = nil }
        var visibleHeroBodyRow: CGFloat?
        for value in [1, 2, 1, 2] {
            state.value = value
            let settled = expectation(description: "Body hero visibility settles")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
            await fulfillment(of: [settled], timeout: 2)
            let screenshot = UIGraphicsImageRenderer(bounds: hosted.bounds).image { _ in
                hosted.drawHierarchy(in: hosted.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "Body hero selected=\(value)"
            attachment.lifetime = .keepAlways
            self.add(attachment)
            let bodyRow = try XCTUnwrap(self.firstRedRow(in: screenshot))
            if value == 2 {
                XCTAssertGreaterThanOrEqual(bodyRow, 88,
                                            "Hiding the body hero must restore the body's top safe-area inset")
            } else if let visibleHeroBodyRow {
                XCTAssertEqual(bodyRow, visibleHeroBodyRow, accuracy: 1, "Revealing the hero must restore its layout")
            } else {
                XCTAssertGreaterThan(bodyRow, 0, "The visible hero must occupy space before the body")
                visibleHeroBodyRow = bodyRow
            }
            XCTAssertEqual(coordinator.actions.count, 1)
        }
    }

    func testNestedWrapperPromotionKeepsRegistrationStableAndRestoresFallback() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let button = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        let wrapper = PaywallComponent.stack(.init(
            components: [button], size: .init(width: .fill, height: .fixed(80))
        ))
        let model = try StackComponentViewModel(component: .init(components: [wrapper]), localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        let state = NativeRegistrationTestState()
        var height: CGFloat = -1
        var dismissals = 0
        let content = StackComponentView(viewModel: model, onDismiss: { dismissals += 1 })
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { proxy in
                Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
            })
            .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
        let (window, _) = Self.host(Self.nativeLayoutEnvironment(
            NativeWrapperPresentationTestView(state: state, content: content), coordinator: coordinator
        ))
        defer { window.isHidden = true; window.rootViewController = nil }
        var actionID: UUID?
        for (value, expected): (Int, CGFloat) in [(0, 0), (1, 80), (0, 0), (1, 80), (0, 0)] {
            state.value = value
            let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                abs(height - expected) < 0.5 && coordinator.actions.count == 1
            }, object: nil)
            await fulfillment(of: [settled], timeout: 2)
            let currentID = try XCTUnwrap(coordinator.actions.first?.id)
            if let actionID { XCTAssertEqual(currentID, actionID, "Promotion must not remount action registration") }
            actionID = currentID
        }
        try await coordinator.performAction(id: XCTUnwrap(actionID))
        XCTAssertEqual(dismissals, 1)
    }

    func testNativePromotionPreservesDecoratedAndConditionalWrappers() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let button = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        for conditional in [false, true] {
            func wrapper(_ children: [PaywallComponent]) -> PaywallComponent {
                .stack(.init(
                    components: children, size: .init(width: .fixed(80), height: .fixed(80)),
                    backgroundColor: conditional ? nil : .init(light: .hex("#FF0000")),
                    overrides: conditional ? [.init(conditions: [.selected], properties: .init(
                        backgroundColor: .init(light: .hex("#0000FF"))
                    ))] : nil
                ))
            }
            func stack(_ child: PaywallComponent) -> PaywallComponent.StackComponent {
                let marker = PaywallComponent.stack(.init(
                    components: [], size: .init(width: .fixed(20), height: .fixed(20)),
                    backgroundColor: .init(light: .hex("#0000FF"))
                ))
                return .init(components: [marker, child, marker],
                             size: .init(width: .fixed(200), height: .fixed(200)), spacing: 12)
            }
            let reference = try await self.renderNativeStack(stack(wrapper([])), actions: 0)
            let native = try await self.renderNativeStack(stack(wrapper([button])), actions: 1)
            XCTAssertEqual(native.pngData(), reference.pngData(),
                           "Authored decoration and uncertain layout must remain")
        }
    }

    func testNativeHeaderPreservesDecorativeEmptyStacks() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let button = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        for decoration in 0..<3 {
            let decorated = PaywallComponent.stack(.init(
                components: [], size: .init(width: .fill, height: .fixed(60)),
                backgroundColor: decoration == 0 ? .init(light: .hex("#FF0000")) : nil,
                border: decoration == 1 ? .init(color: .init(light: .hex("#000000")), width: 2) : nil,
                shadow: decoration == 2 ? .init(color: .init(light: .hex("#000000")), radius: 2, x: 0, y: 0) : nil
            ))
            let stack = PaywallComponent.StackComponent(components: [button, decorated], spacing: 0)
            let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
                locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
            ), colorScheme: .light)
            var height: CGFloat = -1
            let view = HeaderComponentView(viewModel: .init(
                component: .init(stack: stack), stackViewModel: model, firstItemIgnoresSafeArea: false
            ), onDismiss: {})
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
                })
                .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
            let coordinator = NativePaywallCloseCoordinator()
            let (window, _) = Self.host(Self.nativeLayoutEnvironment(view, coordinator: coordinator))
            defer { window.isHidden = true; window.rootViewController = nil }
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                height >= 60 && coordinator.actions.count == 1
            }, object: nil)
            await fulfillment(of: [visible], timeout: 2)
            XCTAssertGreaterThanOrEqual(height, 60, "Decoration is visible content even without children")
        }
    }

    func testCollapsedHiddenHeroRestoresRootBodySafeArea() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let imageURL = try Self.makeHeroImageURL()
        defer { try? FileManager.default.removeItem(at: imageURL) }
        let image = PaywallComponent.image(.init(visible: false, source: .init(light: .init(
            width: 1, height: 1, original: URL(string: "https://example.com/hidden.png")!,
            heic: URL(string: "https://example.com/hidden.png")!,
            heicLowRes: URL(string: "https://example.com/hidden.png")!
        ))))
        let close = PaywallComponent.button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        let marker = PaywallComponent.stack(.init(
            components: [], size: .init(width: .fill, height: .fixed(20)),
            backgroundColor: .init(light: .hex("#FF0000"))
        ))
        let unrelatedCard = PaywallComponent.stack(.init(components: [.image(.init(
            source: .init(light: .init(
                width: 1, height: 1, original: imageURL, heic: imageURL, heicLowRes: imageURL
            )), size: .init(width: .fill, height: .fixed(60))
        )), marker], dimension: .zlayer(.top)))
        for bodyLayout in 0..<3 {
            var results: [Int: CGFloat] = [:]
            var screenshots: [Int: Data] = [:]
            for heroLocation in 0..<3 {
                let header = PaywallComponent.StackComponent(components: (heroLocation == 1 ? [image] : []) + [close])
                let body = PaywallComponent.StackComponent(
                    components: (heroLocation == 2 ? [image] : []) + [.stack(.init(
                        components: [marker, unrelatedCard], spacing: 0
                    ))], dimension: bodyLayout == 0 ? .vertical(.center, .start) : .zlayer(.top)
                )
                let config = PaywallComponentsData.PaywallComponentsConfig(
                    stack: bodyLayout == 2 ? .init(components: [.stack(body)]) : body,
                    header: .init(stack: header), stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
                var factory = ViewModelFactory()
                let root = try factory.toRootViewModel(
                    componentsConfig: config,
                    offering: .init(identifier: "native-layout", serverDescription: "", availablePackages: [],
                                    webCheckoutUrl: nil),
                    localizationProvider: .init(locale: Locale(identifier: "en_US"),
                                                localizedStrings: ["Close": .string("Close")]),
                    uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()), colorScheme: .light
                )
                let view = RootView(viewModel: root, onDismiss: {}, defaultPackage: nil)
                let coordinator = NativePaywallCloseCoordinator()
                let (window, hosted) = Self.host(Self.nativeLayoutEnvironment(
                    view, coordinator: coordinator,
                    safeAreaInsets: EdgeInsets(top: 88, leading: 0, bottom: 0, trailing: 0)
                ))
                defer { window.isHidden = true; window.rootViewController = nil }
                let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    coordinator.actions.count == 1
                }, object: nil)
                await fulfillment(of: [registered], timeout: 2)
                let settled = expectation(description: "Native header inset settled")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
                await fulfillment(of: [settled], timeout: 2)
                let screenshot = UIGraphicsImageRenderer(bounds: hosted.bounds).image { _ in
                    hosted.drawHierarchy(in: hosted.bounds, afterScreenUpdates: true)
                }
                results[heroLocation] = try XCTUnwrap(self.firstRedRow(in: screenshot))
                screenshots[heroLocation] = screenshot.pngData()
            }
            for heroLocation in [1, 2] {
                XCTAssertEqual(try XCTUnwrap(results[heroLocation]), try XCTUnwrap(results[0]), accuracy: 1,
                               "A hidden hero must match the layout with no hero: bodyLayout=\(bodyLayout)")
                XCTAssertGreaterThanOrEqual(try XCTUnwrap(results[heroLocation]), 88)
                XCTAssertEqual(screenshots[heroLocation], screenshots[0],
                               "Restoring the hero inset must preserve unrelated card overlays")
            }
        }
    }

    private static func makeHeroImageURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("native-hero-\(UUID()).png")
        let hero = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        try XCTUnwrap(hero.pngData()).write(to: url)
        return url
    }

    private func firstRedRow(in image: UIImage) -> CGFloat? {
        guard let cgImage = image.cgImage else { return nil }
        let rowBytes = cgImage.width * 4
        guard let context = CGContext(
            data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: rowBytes,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ), let data = context.data else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        let bytes = data.assumingMemoryBound(to: UInt8.self)
        for row in 0..<cgImage.height {
            for column in 0..<cgImage.width {
                let offset = row * rowBytes + column * 4
                if bytes[offset] > 200 && bytes[offset + 1] < 50 && bytes[offset + 2] < 50 {
                    return CGFloat(row) / image.scale
                }
            }
        }
        return nil
    }

    private static func nativeLayoutEnvironment<Content: View>(
        _ content: Content, coordinator: NativePaywallCloseCoordinator, safeAreaInsets: EdgeInsets = EdgeInsets()
    ) -> some View {
        content.environment(\.nativePaywallCloseCoordinator, coordinator)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environment(\.safeAreaInsets, safeAreaInsets)
    }

    func testNativeButtonsDoNotConsumeMainOrFooterStackSpacing() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let marker = PaywallComponent.stack(.init(components: [], size: .init(width: .fill, height: .fixed(20))))
        let stack = PaywallComponent.StackComponent(components: [marker, .button(.init(
            action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        )), marker], spacing: 24)
        let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
            locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
        ), colorScheme: .light)
        let coordinator = NativePaywallCloseCoordinator()
        var height: CGFloat = -1
        let view = StackComponentView(viewModel: model, onDismiss: {})
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { geometry in
                Color.clear.preference(key: NativeRegistrationHeightKey.self, value: geometry.size.height)
            })
            .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                introEligibilityChecker: BaseSnapshotTest.eligibleChecker
            ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        let (window, _) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1 && abs(height - 64) < 0.5
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        XCTAssertEqual(height, 64, accuracy: 0.5)
    }

    func testNativeHeaderTracksHiddenSiblingsAndPreservesBadgesAcrossOverrides() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        for (hidesStack, hasBadge) in [(false, false), (true, false), (false, true), (true, true)] {
            let title = PaywallComponent.TextComponent(
                visible: hidesStack, text: "Title", color: .init(light: .hex("#000000")),
                overrides: hidesStack ? nil : [.init(conditions: [.selected], properties: .init(visible: true))]
            )
            let sibling: PaywallComponent = hidesStack ? .stack(.init(
                visible: false, components: [.text(title)],
                overrides: [.init(conditions: [.selected], properties: .init(visible: true))]
            )) : .text(title)
            let stack = PaywallComponent.StackComponent(
                components: [.button(.init(action: .navigateBack, stack: Self.makeButtonStack(label: "Close"),
                                           useNativeIfPossible: true)), sibling],
                size: .init(width: .fill, height: .fixed(100)),
                backgroundColor: .init(light: .hex("#FF00FF")),
                badge: hasBadge ? .init(style: .overlaid, alignment: .top, stack: .init(
                    components: [], size: .init(width: .fixed(20), height: .fixed(20)),
                    backgroundColor: .init(light: .hex("#FF0000"))
                )) : nil
            )
            let model = try StackComponentViewModel(component: stack, localizationProvider: .init(
                locale: Locale(identifier: "en_US"),
                localizedStrings: ["Title": .string("Title"), "Close": .string("Close")]
            ), colorScheme: .light)
            let state = NativeRegistrationTestState()
            var height: CGFloat = -1
            let content = HeaderComponentView(viewModel: .init(
                component: .init(stack: stack), stackViewModel: model, firstItemIgnoresSafeArea: false
            ), onDismiss: {})
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
                })
                .onPreferenceChange(NativeRegistrationHeightKey.self) { height = $0 }
                .environment(\.nativePaywallCloseCoordinator, NativePaywallCloseCoordinator())
                .environmentObject(PurchaseHandler.default())
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
                .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
                .environment(\.safeAreaInsets, EdgeInsets())
            let (window, _) = Self.host(NativeHeaderVisibilityTestView(state: state, content: content))
            defer { window.isHidden = true; window.rootViewController = nil }
            for (value, expected) in [(1, CGFloat(hasBadge ? 100 : 0)), (2, 100), (1, hasBadge ? 100 : 0)] {
                state.value = value
                let resized = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    abs(height - expected) < 0.5
                }, object: nil)
                await fulfillment(of: [resized], timeout: 2)
            }
        }
    }

    func testButtonWithVisibleFalse_IsNotRendered() throws {
        let viewModel = try Self.makeViewModel(
            component: PaywallComponent.ButtonComponent(
                visible: false,
                action: .navigateBack,
                stack: Self.makeButtonStack(label: "Close")
            )
        )

        let view = ButtonComponentView(viewModel: viewModel, onDismiss: {})
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(
                IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
            )
            .environmentObject(
                PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker())
            )
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())

        let (window, hostedView) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertFalse(
            hostedView.containsText("Close"),
            "A button with visible=false should not be rendered."
        )
    }

    func testSelectedOverrideVisible_False_HidesWhenSelected() throws {
        let viewModel = try Self.makeViewModel(
            component: PaywallComponent.ButtonComponent(
                action: .navigateBack,
                stack: Self.makeButtonStack(label: "Close"),
                overrides: [
                    .init(conditions: [.selected], properties: .init(visible: false))
                ]
            )
        )

        let view = ButtonComponentView(viewModel: viewModel, onDismiss: {})
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(
                IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
            )
            .environmentObject(
                PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker())
            )
            .environment(\.componentViewState, .selected)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())

        let (window, hostedView) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertFalse(
            hostedView.containsText("Close"),
            "A button with a .selected override that hides should not render when selected."
        )
    }

    func testNativeButtonInNestedStackBadgeKeepsItsActionRegistered() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let badge = PaywallComponent.Badge(
            style: .overlaid, alignment: .top,
            stack: .init(components: [.button(.init(
                action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
            ))])
        )
        for insideButton in [false, true] {
            let label = PaywallComponent.StackComponent(
                components: Self.makeButtonStack(label: "Close").components, badge: badge
            )
            let child: PaywallComponent = insideButton
                ? .stack(.init(components: [.button(.init(action: .restorePurchases, stack: label))]))
                : .stack(label)
            let model = try StackComponentViewModel(
                component: .init(components: [child]),
                localizationProvider: .init(locale: Locale(identifier: "en_US"),
                                            localizedStrings: ["Close": .string("Close")]),
                colorScheme: .light
            )
            let coordinator = NativePaywallCloseCoordinator()
            var backActions = 0
            let view = StackComponentView(viewModel: model, onDismiss: {})
                .environment(\.workflowNavigateBackHandler, { backActions += 1 })
                .environment(\.nativePaywallCloseCoordinator, coordinator)
                .environmentObject(PurchaseHandler.default())
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
                .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
                .environment(\.safeAreaInsets, EdgeInsets())
            let (window, _) = Self.host(view)
            defer { window.isHidden = true; window.rootViewController = nil }
            let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                coordinator.actions.count == 1
            }, object: nil)
            await fulfillment(of: [registered], timeout: 2)
            let id = try XCTUnwrap(coordinator.actions.first?.id)
            let settled = expectation(description: "Badge registration remains stable")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settled.fulfill() }
            await fulfillment(of: [settled], timeout: 2)
            XCTAssertEqual(coordinator.actions.map(\.id), [id])
            try await coordinator.performAction(id: id)
            XCTAssertEqual(backActions, 1)
        }
    }

    func testPromotingNativeButtonsDoesNotRemountSiblingCarousel() async throws {
        try XCTSkipIf(UIApplication.shared.connectedScenes.isEmpty, "Requires UnitTestsHostApp")
        let dimensions: [PaywallComponent.Dimension] = [
            .vertical(.leading, .start), .horizontal(.center, .start), .zlayer(.center),
            .vertical(.leading, .spaceBetween), .horizontal(.center, .spaceBetween),
            .vertical(.leading, .spaceAround), .horizontal(.center, .spaceAround),
            .vertical(.leading, .spaceEvenly), .horizontal(.center, .spaceEvenly)
        ]
        for dimension in dimensions {
            let close = PaywallComponent.button(.init(
                action: .navigateBack, stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
            ))
            let model = try StackComponentViewModel(component: .init(
                components: [close, .carousel(.init(pages: [Self.makeButtonStack(label: "Close")])), close],
                dimension: dimension, size: .init(width: .fixed(280), height: .fixed(180)), spacing: 8
            ), localizationProvider: .init(
                locale: Locale(identifier: "en_US"), localizedStrings: ["Close": .string("Close")]
            ), colorScheme: .light)
            guard case .carousel(let carousel) = model.viewModels[1] else { return XCTFail("Missing carousel") }
            var appearances = 0
            carousel.onViewAppear = { appearances += 1 }
            let state = NativeRegistrationTestState()
            state.showsButton = false
            let content = StackComponentView(viewModel: model, onDismiss: {})
                .environment(\.nativePaywallCloseCoordinator, NativePaywallCloseCoordinator())
                .environmentObject(PurchaseHandler.default())
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
                .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
                .environment(\.safeAreaInsets, EdgeInsets())
            let (window, _) = Self.host(NativePromotionTestView(state: state, content: content))
            defer { window.isHidden = true; window.rootViewController = nil }
            for presented in [false, true, false] {
                state.showsButton = presented
                let settled = expectation(description: "Native promotion settled")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settled.fulfill() }
                await fulfillment(of: [settled], timeout: 2)
                XCTAssertEqual(appearances, 1, "Promotion must preserve carousel state in \(dimension)")
            }
        }
    }

    func testNativeRegistrationPreservesDismissalAndAnalytics() async throws {
        let coordinator = NativePaywallCloseCoordinator()
        let viewModel = try Self.makeViewModel(component: .init(
            name: "close", action: .navigateBack,
            stack: Self.makeButtonStack(label: "Close"), useNativeIfPossible: true
        ))
        var dismissals = 0
        var interactions: [PaywallEvent.ComponentInteractionData] = []
        let view = Self.nativeTestView(viewModel: viewModel, onDismiss: { dismissals += 1 })
            .environment(\.nativePaywallCloseCoordinator, coordinator)
            .environment(\.componentInteractionLogger, ComponentInteractionLogger { event in
                interactions.append(event)
                return true
            })
        let (window, hostedView) = Self.host(view)
        defer { window.isHidden = true; window.rootViewController = nil }
        let registered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            coordinator.actions.count == 1
        }, object: nil)
        await fulfillment(of: [registered], timeout: 2)
        XCTAssertFalse(hostedView.containsText("Close"))
        try await coordinator.performAction(id: XCTUnwrap(coordinator.actions.first?.id))
        XCTAssertEqual(dismissals, 1)
        XCTAssertEqual(interactions.count, 1)
        XCTAssertEqual(interactions.first?.componentValue, "navigate_back")
        XCTAssertEqual(interactions.first?.componentName, "close")
    }

    func testNativePreferenceWithoutHostRetainsConfiguredButton() async {
        let fallback = expectation(description: "Configured button is rendered without a native host")
        let button = NativePaywallCloseButton(
            enabled: true, accessibilityLabel: "Close", action: {},
            content: { Button("Close") {}.onAppear { fallback.fulfill() } }
        )
        let (window, _) = Self.host(button)
        defer { window.isHidden = true; window.rootViewController = nil }
        await fulfillment(of: [fallback], timeout: 2)
    }

    private static func nativeTestView(
        viewModel: ButtonComponentViewModel, onDismiss: @escaping () -> Void
    ) -> some View {
        ButtonComponentView(viewModel: viewModel, onDismiss: onDismiss)
            .environmentObject(PurchaseHandler.default())
            .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
            .environmentObject(IntroOfferEligibilityContext(
                    introEligibilityChecker: BaseSnapshotTest.eligibleChecker
                ))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environment(\.componentViewState, .default)
            .environment(\.screenCondition, .compact)
            .environment(\.safeAreaInsets, EdgeInsets())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ButtonComponentViewTests {

    static func makeViewModel(
        component: PaywallComponent.ButtonComponent
    ) throws -> ButtonComponentViewModel {
        let offering = Offering(
            identifier: "default",
            serverDescription: "",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let localizationProvider = LocalizationProvider(locale: Locale(identifier: "en_US"), localizedStrings: [
            "Close": .string("Close")
        ])
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()

        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            colorScheme: .light
        )

        return try ButtonComponentViewModel(
            component: component,
            localizationProvider: localizationProvider,
            offering: offering,
            stackViewModel: stackViewModel,
            uiConfigProvider: uiConfigProvider
        )
    }

    static func makeButtonStack(label: String) -> PaywallComponent.StackComponent {
        return PaywallComponent.StackComponent(
            components: [
                .text(
                    PaywallComponent.TextComponent(
                        text: label,
                        color: .init(light: .hex("#000000"))
                    )
                )
            ]
        )
    }

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(
            rootView: view
                .frame(width: 300, height: 200)
        )
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 200)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        return (window, controller.view)
    }

}

private extension UIView {

    func containsText(_ text: String) -> Bool {
        if let label = self as? UILabel, label.text == text {
            return true
        }

        if self.accessibilityLabel == text {
            return true
        }

        return self.subviews.contains { $0.containsText(text) }
    }

}

@available(iOS 15.0, *)
private struct NativeInlineSheetRegistrationTestView: View {
    @ObservedObject var state: NativeRegistrationTestState
    let sheet: SheetViewModel

    var body: some View {
        VStack {
            NativePaywallCloseButton(enabled: true, accessibilityLabel: "Back", role: .back,
                                     action: { self.state.performed += 1 }, content: { EmptyView() })
            NativePaywallCloseButton(enabled: true, accessibilityLabel: "Close",
                                     action: { self.state.performed += 1 }, content: { EmptyView() })
        }
        .bottomSheet(sheet: Binding(
            get: { self.state.value == 2 ? self.sheet : nil },
            set: { _ in self.state.value = 1 }
        ), safeAreaInsets: .init())
        .environment(\.nativePaywallInteractionEnabled, self.state.showsButton)
    }
}

@available(iOS 15.0, *)
private struct NativeHeaderVisibilityTestView<Content: View>: View {
    @ObservedObject var state: NativeRegistrationTestState
    let content: Content
    var body: some View {
        self.content.environment(\.componentViewState, self.state.value == 1 ? .default : .selected)
    }
}

@available(iOS 15.0, *)
private struct NativePromotionTestView<Content: View>: View {
    @ObservedObject var state: NativeRegistrationTestState
    let content: Content
    var body: some View {
        self.content.environment(\.nativePaywallControlsPresented, self.state.showsButton)
    }
}

@MainActor
private final class NativeRegistrationTestState: ObservableObject {
    @Published var value = 1
    @Published var showsButton = true
    var performed = 0
}

@available(iOS 15.0, *)
private struct NativeCarouselRegistrationTestView: View {
    @ObservedObject var state: NativeRegistrationTestState
    var body: some View {
        VStack {
            ForEach(0..<9) { index in
                NativePaywallCloseButton(
                    enabled: true, accessibilityLabel: "Slide \(index)",
                    role: index.isMultiple(of: 2) ? .back : .close,
                    action: { self.state.performed = index }, content: { EmptyView() }
                )
                .environment(\.carouselState, CarouselState(
                    activeIndex: self.state.value, pageIndex: index,
                    ancestorDistanceFromActive: self.state.showsButton ? 0 : 1
                ))
            }
        }
    }
}

@available(iOS 15.0, *)
private struct NativeRegistrationTestView: View {
    @ObservedObject var state: NativeRegistrationTestState
    var body: some View {
        let value = self.state.value
        VStack(spacing: 24) {
            Color.red.frame(height: 20)
            if self.state.showsButton {
                NativePaywallCloseButton(enabled: true, accessibilityLabel: "Close",
                                         action: { self.state.performed = value },
                                         content: { Color.clear.frame(height: 40) })
            }
            Color.blue.frame(height: 20)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: NativeRegistrationHeightKey.self, value: proxy.size.height)
        })
    }
}

@available(iOS 15.0, *)
private struct NativeWrapperPresentationTestView<Content: View>: View {
    @ObservedObject var state: NativeRegistrationTestState
    let content: Content
    var body: some View {
        self.content.environment(\.nativePaywallControlsPresented, self.state.value == 0)
    }
}

private struct NativeRegistrationHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

#endif
