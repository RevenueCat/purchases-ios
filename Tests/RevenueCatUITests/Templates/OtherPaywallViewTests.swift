//
//  DefaultPaywallViewTests.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

import Nimble
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SnapshotTesting
import SwiftUI
import XCTest

#if canImport(UIKit)
import UIKit
#endif

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
        let title = "V2 paywall content"
        let offering = try Self.v2Offering(title: title)
        let view = PaywallView(
            configuration: .init(
                offering: offering,
                mode: .fullScreen,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
        )

        let (window, hostedView) = Self.host(view, size: Self.fullScreenSize)
        defer { window.isHidden = true }

        expect(hostedView.containsText(title)).toEventually(beTrue())
    }

    func testFullScreenV1CanRenderWithoutCustomerInfo() {
        let view = PaywallView(
            configuration: .init(
                offering: TestData.offeringWithIntroOffer,
                mode: .fullScreen,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
        )

        let (window, hostedView) = Self.host(view, size: Self.fullScreenSize)
        defer { window.isHidden = true }

        expect(hostedView.containsText(matching: "curiosity")).toEventually(beTrue())
    }

    func testFooterCanRenderWithoutCustomerInfo() {
        let view = PaywallView(
            configuration: .init(
                offering: TestData.offeringWithIntroOffer,
                mode: .footer,
                introEligibility: .producing(eligibility: .eligible),
                purchaseHandler: .mock()
            )
        )

        let (window, hostedView) = Self.host(view, size: Self.footerSize)
        defer { window.isHidden = true }

        expect(hostedView.containsText(matching: "Purchase")).toEventually(beTrue())
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

    static func host<Content: View>(
        _ view: Content,
        size: CGSize
    ) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()

        return (window, controller.view)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension UIView {

    func containsText(_ text: String) -> Bool {
        return self.containsText(matching: text, exact: true)
    }

    func containsText(matching text: String) -> Bool {
        return self.containsText(matching: text, exact: false)
    }

    private func containsText(matching text: String, exact: Bool) -> Bool {
        if let label = self as? UILabel, let labelText = label.text {
            if exact ? labelText == text : labelText.contains(text) {
                return true
            }
        }

        if let accessibilityLabel = self.accessibilityLabel {
            if exact ? accessibilityLabel == text : accessibilityLabel.contains(text) {
                return true
            }
        }

        return self.subviews.contains { $0.containsText(matching: text, exact: exact) }
    }

}
#endif

#endif
