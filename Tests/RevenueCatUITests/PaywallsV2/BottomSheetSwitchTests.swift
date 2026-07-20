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

    static func makeSheetViewModel(id: String, text: String) throws -> SheetViewModel {
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        let localization = LocalizationProvider(locale: Locale(identifier: "en_US"), localizedStrings: [:])
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

        let stackViewModel = try factory.toStackViewModel(
            component: stack,
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
            stack: stack,
            backgroundBlur: false,
            size: .init(width: .fill, height: .fit(nil))
        )

        return SheetViewModel(sheet: sheet, sheetStackViewModel: stackViewModel)
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
