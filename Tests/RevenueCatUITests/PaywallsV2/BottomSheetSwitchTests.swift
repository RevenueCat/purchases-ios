//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BottomSheetSwitchTests.swift
//
//  Created by RevenueCat on 7/14/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class BottomSheetSwitchTests: TestCase {

    func testRelativeSheetHeightIsClampedToMinMax() {
        let clamped = PaywallComponent.SizeConstraint.relative(0.5, .init(min: 300, max: 400))

        XCTAssertEqual(BottomSheetOverlayModifier.resolvedHeight(for: clamped, parentHeight: 1000), 400)
        XCTAssertEqual(BottomSheetOverlayModifier.resolvedHeight(for: clamped, parentHeight: 700), 350)
        XCTAssertEqual(BottomSheetOverlayModifier.resolvedHeight(for: clamped, parentHeight: 400), 300)
        XCTAssertNil(BottomSheetOverlayModifier.resolvedHeight(for: clamped, parentHeight: nil))
        XCTAssertEqual(BottomSheetOverlayModifier.resolvedHeight(for: .fixed(120), parentHeight: nil), 120)
        XCTAssertNil(BottomSheetOverlayModifier.resolvedHeight(for: .fit(nil), parentHeight: 1000))
    }

    /// Regression test for a bug where switching from one bottom sheet to another before the
    /// dismiss animation finished kept the previous sheet's content alive (most visibly, a video
    /// from the previous sheet kept playing in the newly-opened sheet).
    ///
    /// Root cause: `BottomSheetOverlayModifier` rendered its content from a single `if let`
    /// slot with no `.id()`, so identity was positional. A rapid switch reused the same view
    /// identity while the dismiss animation was still in flight, `onAppear` never re-fired, and
    /// state latched in `onAppear` (such as a video's cached URL) persisted.
    ///
    /// Fix: `.id(sheetViewModel.sheet.id)` is applied to the sheet content. When the presented
    /// sheet changes, its identity changes, SwiftUI disposes the previous sheet's subtree and
    /// builds the new one from scratch, and `onAppear` fires for the new sheet.
    ///
    /// The test verifies the fix by counting how many times the sheet content appears. It shows
    /// sheet A, then switches directly to sheet B without letting the sheet settle back to `nil`.
    /// With the fix the content is disposed and recreated → the appear callback fires again.
    /// Without the fix the content is reused → the appear callback does not fire for sheet B.
    func testSwitchingSheetsRecreatesContent() throws {
        let holder = SheetHolder()
        holder.sheet = try Self.makeSheetViewModel(id: "sheetA", text: "Sheet A")

        var appearCount = 0

        let view = SheetSwitchTestHostView(
            holder: holder,
            onSheetContentAppear: { appearCount += 1 }
        )
        .environmentObject(PurchaseHandler.default())
        .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
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
        .frame(width: 400, height: 600)

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Sheet A is presented on initial layout, so its content must have appeared exactly once.
        XCTAssertEqual(appearCount, 1, "Sheet A content must appear once after it is presented")

        // Switch directly to sheet B without settling back to `nil`, mimicking a rapid
        // dismiss→open while the dismiss animation is still in flight.
        holder.sheet = try Self.makeSheetViewModel(id: "sheetB", text: "Sheet B")

        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        // After switching, sheet B's content must appear.
        //
        // BUG (now fixed): with a single unkeyed slot SwiftUI reused sheet A's view identity —
        // `onAppear` never fired for sheet B and the old subtree (e.g. a playing video) lived on.
        // The count stayed at 1.
        //
        // FIX: `.id(sheetViewModel.sheet.id)` forces SwiftUI to dispose sheet A's content and
        // build sheet B's from scratch, so `onAppear` fires for sheet B. The count becomes 2.
        XCTAssertEqual(
            appearCount,
            2,
            "Sheet B content must appear after switching sheets, meaning sheet A's content was disposed"
        )
    }

}

// MARK: - Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class SheetHolder: ObservableObject {
    @Published var sheet: SheetViewModel?
    var openSheet: ((SheetViewModel) -> Void)?
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct SheetSwitchTestHostView: View {

    @ObservedObject var holder: SheetHolder
    let onSheetContentAppear: () -> Void

    var body: some View {
        Color.clear
            .bottomSheet(
                sheet: Binding(
                    get: { self.holder.sheet },
                    set: { self.holder.sheet = $0 }
                ),
                safeAreaInsets: EdgeInsets(),
                onSheetContentAppear: self.onSheetContentAppear
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BottomSheetSwitchTests {

    static func makeSheetViewModel(id: String, text: String, package: Package? = nil) throws -> SheetViewModel {
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: package.map { [$0] } ?? [],
            webCheckoutUrl: nil
        )
        let localization = LocalizationProvider(
            locale: Locale(identifier: "en_US"), localizedStrings: [text: .string(text)]
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()

        let stack = PaywallComponent.StackComponent(
            components: [
                .text(PaywallComponent.TextComponent(
                    text: text,
                    color: .init(light: .hex("#000000"))
                ))
            ]
        )

        let contentStack = package.map { package in
            PaywallComponent.StackComponent(components: [.package(.init(
                packageID: package.identifier, isSelectedByDefault: true,
                applePromoOfferProductCode: nil, stack: stack
            ))])
        } ?? stack
        let stackViewModel = try factory.toStackViewModel(
            component: contentStack,
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: localization,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            colorScheme: .light
        )

        let sheet = PaywallComponent.ButtonComponent.Sheet(
            id: id,
            name: nil,
            stack: contentStack,
            backgroundBlur: false,
            size: .init(width: .fill, height: .fit(nil))
        )

        return SheetViewModel(sheet: sheet, sheetStackViewModel: stackViewModel,
                              packageValidator: factory.packageValidator)
    }

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 400, height: 600)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        return (window, controller.view)
    }

}

#endif

#if os(iOS)

@available(iOS 15.0, *)
extension BottomSheetSwitchTests {

    func testPW11SheetOwnsSelectionAndVariablesWithoutChangingTabMemory() async throws {
        let fixture = try PackageResolutionTestFixture(competingDefaults: true)
        let validator = fixture.state.viewModelFactory.packageValidator
        XCTAssertFalse(validator.packages.contains { $0.identifier == "annual_xl" })
        XCTAssertTrue(fixture.state.packages.contains { $0.identifier == "annual_xl" },
                      "Sheet packages must still participate in offer loading")
        XCTAssertEqual(validator.defaultSelectedPackage(in: .provisional)?.identifier, "$rc_monthly")
        let holder = SheetHolder()
        let button = try XCTUnwrap(fixture.state.rootViewModel.stackViewModel.viewModels.compactMap {
            if case .button(let button) = $0, button.sheetStackViewModel != nil { return button }
            return nil
        }.first)
        guard case .sheet(let sheet) = button.action else { return XCTFail("Expected a sheet action") }
        let model = SheetViewModel(
            sheet: try XCTUnwrap(sheet),
            sheetStackViewModel: try XCTUnwrap(button.sheetStackViewModel),
            packageValidator: button.sheetPackageValidator
        )
        let host = PackageResolutionSheetHost(fixture: fixture, holder: holder)
        let (window, _) = Self.host(host)
        defer {
            holder.openSheet = nil
            window.isHidden = true
            window.rootViewController = nil
        }
        try await PackageResolutionTestFixture.settlePresentation()
        XCTAssertEqual(fixture.context.package?.identifier, "$rc_annual")
        fixture.tabs.tabControlContext.selectedTabId = "tab-2"
        try await PackageResolutionTestFixture.settlePresentation()
        XCTAssertEqual(fixture.context.package?.identifier, "monthly_xl")
        let tabContext = try XCTUnwrap(fixture.context.tabsState(for: fixture.tabs).contextsByTabId["tab-2"])
        let previousTabPackage = tabContext.package
        let previousVariables = fixture.context.variableContext

        try XCTUnwrap(holder.openSheet)(model)
        XCTAssertEqual(fixture.context.package?.identifier, "annual_xl", "Activation is synchronous")
        try await PackageResolutionTestFixture.settlePresentation()
        XCTAssertEqual(fixture.context.package?.identifier, "annual_xl", "Background reconcile cannot take ownership")
        XCTAssertEqual(tabContext.package?.identifier, previousTabPackage?.identifier)
        XCTAssertNil(tabContext.manuallySelectedPackage, "Opening a sheet isn't a manual tab choice")
        let variables = PackageContext.VariableContext(
            packages: try XCTUnwrap(model.packageValidator).packages, showZeroDecimalPlacePrices: false
        )
        XCTAssertEqual(fixture.context.variableContext.exactMostExpensivePricePerMonth,
                       variables.exactMostExpensivePricePerMonth)
        // Replacing the active sheet takes ownership before its content mounts. Updates from
        // the outgoing sheet (including an animation's last render) cannot overwrite the new one.
        let outgoingContext = try XCTUnwrap(fixture.context.presentedSheetContext)
        let replacement = try Self.makeSheetViewModel(
            id: "replacement", text: "Replacement", package: TestData.monthlyPackage
        )
        try XCTUnwrap(holder.openSheet)(replacement)
        try await PackageResolutionTestFixture.settlePresentation()
        outgoingContext.update(package: fixture.offering.package(identifier: "annual_xl"),
                               variableContext: outgoingContext.variableContext)
        try await PackageResolutionTestFixture.settlePresentation()
        XCTAssertEqual(fixture.context.package?.identifier, TestData.monthlyPackage.identifier)
        XCTAssertEqual(tabContext.package?.identifier, previousTabPackage?.identifier)
        XCTAssertNotEqual(previousVariables.exactMostExpensivePricePerMonth,
                          fixture.context.variableContext.exactMostExpensivePricePerMonth)

    }

}

@available(iOS 15.0, *)
private struct PackageResolutionSheetHost: View {

    let fixture: PackageResolutionTestFixture
    @ObservedObject var holder: SheetHolder

    var body: some View {
        VStack {
            self.fixture.view()
            SheetOpenProbe(holder: self.holder)
        }
            .modifier(RootPackageSelectionSheetModifier(
                defaultPackage: self.fixture.state.viewModelFactory.packageValidator
                    .defaultSelectedPackage(in: .provisional)
            ))
            .environmentObject(self.fixture.context)
            .environmentObject(PurchaseHandler.mock())
            .environmentObject(IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
    }

}

@available(iOS 15.0, *)
private struct SheetOpenProbe: View {

    @Environment(\.openSheet) private var openSheet
    let holder: SheetHolder

    var body: some View {
        Color.clear.frame(height: 1)
            .onAppear { self.holder.openSheet = self.openSheet }
    }

}

#endif
