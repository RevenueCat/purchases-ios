//
//  DefaultPaywallViewTests.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OtherPaywallViewTests: BaseSnapshotTest {

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

    #if !os(tvOS)
    func testFullScreenV2CanRenderWithoutCustomerInfo() throws {
        guard !Purchases.isConfigured else {
            throw XCTSkip("Test requires an empty CustomerInfo cache")
        }

        let title = "V2 paywall content"
        let offering = try Self.v2Offering(title: title)
        let view = PaywallView(
            configuration: .init(
                offering: offering,
                customerInfo: nil,
                mode: .fullScreen,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
        )

        let (window, hostedView) = Self.host(view)
        defer { window.isHidden = true }

        expect(hostedView.containsText(title)).toEventually(beTrue())
    }
    #endif

}

#if !os(tvOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension OtherPaywallViewTests {

    static func v2Offering(title: String) throws -> Offering {
        let data = PaywallComponentsData(
            templateName: "test",
            assetBaseURL: try XCTUnwrap(URL(string: "https://assets.revenuecat.com")),
            componentsConfig: .init(
                base: .init(
                    stack: .init(components: [
                        .text(.init(text: "title", color: .init(light: .hex("#000000"))))
                    ]),
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: [
                "en_US": ["title": .string(title)]
            ],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )

        return Offering(
            identifier: "v2-offering",
            serverDescription: "V2 offering",
            paywallComponents: .init(uiConfig: PreviewUIConfig.make(), data: data),
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.fullScreenSize))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()

        return (window, controller.view)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
#endif

#endif
