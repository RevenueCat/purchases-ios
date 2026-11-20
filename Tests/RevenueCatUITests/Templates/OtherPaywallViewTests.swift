//
//  DefaultPaywallViewTests.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OtherPaywallViewTests: BaseSnapshotTest {

    func testCloseButtonAccessibility() throws {
        var wasDismissed = false
        let (window, view) = Self.hostPaywall(displayCloseButton: true) {
            wasDismissed = true
        }
        defer { window.isHidden = true }

        let closeButton = try XCTUnwrap(view.accessibilityElement(identifier: "paywall_close_button"))
        expect(closeButton.accessibilityLabel) == "Dismiss"
        expect(closeButton.accessibilityTraits.contains(.button)) == true
        expect(closeButton.accessibilityActivate()) == true
        expect(wasDismissed) == true
    }

    func testCloseButtonAccessibilityWhenHidden() {
        let (window, view) = Self.hostPaywall(displayCloseButton: false)
        defer { window.isHidden = true }

        expect(view.accessibilityElement(identifier: "paywall_close_button")).to(beNil())
    }

    func testDisabledCloseButtonRetainsAccessibilityMetadata() throws {
        var wasDismissed = false
        let (window, view) = Self.hostPaywall(
            displayCloseButton: true,
            purchaseHandler: .purchasing()
        ) {
            wasDismissed = true
        }
        defer { window.isHidden = true }

        let closeButton = try XCTUnwrap(view.accessibilityElement(identifier: "paywall_close_button"))
        expect(closeButton.accessibilityLabel) == "Dismiss"
        expect(closeButton.accessibilityTraits.contains(.notEnabled)) == true
        expect(closeButton.accessibilityActivate()) == false
        expect(wasDismissed) == false
    }

    func testLoadingPaywallView() {
        LoadingPaywallView(mode: .fullScreen, displayCloseButton: false, shimmer: false)
            .recordSnapshot(size: Self.fullScreenSize)
    }

    func testLoadingFooterPaywallView() {
        LoadingPaywallView(mode: .footer, displayCloseButton: false, shimmer: false)
            .recordSnapshot(size: Self.footerSize)
    }

    func testLoadingCondensedFooterPaywallView() {
        LoadingPaywallView(mode: .condensedFooter, displayCloseButton: false, shimmer: false)
            .recordSnapshot(size: Self.footerSize)
    }

    private static func hostPaywall(
        displayCloseButton: Bool,
        purchaseHandler: PurchaseHandler = .mock(),
        onDismiss: @escaping () -> Void = {}
    ) -> (UIWindow, UIView) {
        let view = PaywallView(
            configuration: .init(
                offering: TestData.offeringWithIntroOffer.withLocalImages,
                customerInfo: TestData.customerInfo,
                displayCloseButton: displayCloseButton,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: purchaseHandler
            ),
            paywallViewOwnsPurchaseHandler: false
        )
        .onRequestedDismissal(onDismiss)

        return Self.host(view)
    }

    private static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let size = Self.fullScreenSize
        let controller = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        return (window, controller.view)
    }

}

private extension UIView {

    func accessibilityElement(identifier: String) -> NSObject? {
        if self.accessibilityIdentifier == identifier {
            return self
        }

        for element in self.accessibilityElements ?? [] {
            if let identifiable = element as? UIAccessibilityIdentification,
               identifiable.accessibilityIdentifier == identifier {
                return element as? NSObject
            }
        }

        return self.subviews.lazy.compactMap { $0.accessibilityElement(identifier: identifier) }.first
    }

}

#endif
