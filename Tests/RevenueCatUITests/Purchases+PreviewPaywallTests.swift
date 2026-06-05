//
//  Purchases+PreviewPaywallTests.swift
//  RevenueCatTests
//
//  Created by Dave DeLong on 6/4/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Nimble
import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

@available(iOS 15.0, macOS 12.0, *)
class PreviewPaywallTests: TestCase {

    var presenter: PreviewPaywallPresenter { PreviewPaywallPresenter() }

    var paywall: PaywallData {
        PaywallData(id: "abcd",
                    templateName: "",
                    config: TestData.paywallWithNoIntroOffer.config,
                    localization: TestData.localization1,
                    assetBaseURL: TestData.paywallAssetBaseURL)
    }

    var offering: Offering {
        Offering(identifier: "1234",
                 serverDescription: "Main offering",
                 metadata: [:],
                 paywall: paywall,
                 availablePackages: TestData.packages,
                 webCheckoutUrl: nil)
    }

    func testInvalidURLHost() throws {
        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: URL(string: "rc://NOT_THE_RIGHT_HOST?offering_id=1234&paywall_id=abcd")!,
                                     viewController: nil)) == false
    }

    func testInvalidNumberOfParameters() throws {
        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: URL(string: "rc://rc-paywall-preview")!,
                                     viewController: nil)) == false

        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: URL(string: "rc://rc-paywall-preview?offering_id=1234")!,
                                     viewController: nil)) == false

        let urlWithExtraParam = URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=abcd&extra=0000")!
        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: urlWithExtraParam,
                                     viewController: nil)) == false
    }

    func testEmptyParameterValues() throws {
        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: URL(string: "rc://rc-paywall-preview?offering_id=&paywall_id=abcd")!,
                                     viewController: nil)) == false

        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=")!,
                                     viewController: nil)) == false
    }

    func testMissingPresentationContext() throws {
        expect(self.presenter.handle(locateOffering: { _ in return nil },
                                     url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=abcd")!,
                                     viewController: nil)) == false
    }

    func testOfferingsAreLocated() throws {
        let expectation = self.expectation(description: "locate offering")

        expect(self.presenter.handle(
            locateOffering: { offeringID in
                expect(offeringID == "1234") == true
                expectation.fulfill()
                return nil
            },
            url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=abcd")!,
            viewController: MockViewController { })
        ) == true

        self.wait(for: [expectation], timeout: 0.1)
    }

    func testFailingToLocateOfferingDoesntPresent() throws {
        let expectation = self.expectation(description: "show paywall")
        expectation.isInverted = true

        expect(self.presenter.handle(
            locateOffering: { _ in
                throw CocoaError(.userCancelled)
            },
            url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=abcd")!,
            viewController: MockViewController { expectation.fulfill() })
        ) == true

        self.wait(for: [expectation], timeout: 0.1)
    }

    func testNilOfferingDoesntPresent() throws {
        let expectation = self.expectation(description: "show paywall")
        expectation.isInverted = true

        expect(self.presenter.handle(
            locateOffering: { _ in
                return nil
            },
            url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=abcd")!,
            viewController: MockViewController { expectation.fulfill() })
        ) == true

        self.wait(for: [expectation], timeout: 0.1)
    }

    func testWrongPaywallIDDoesntPresent() throws {
        let expectation = self.expectation(description: "show paywall")
        expectation.isInverted = true

        expect(self.presenter.handle(
            locateOffering: { _ in
                return self.offering
            },
            url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=wxyz")!,
            viewController: MockViewController { expectation.fulfill() })
        ) == true

        self.wait(for: [expectation], timeout: 0.1)
    }

    func testHappyPath() throws {
        let expectation = self.expectation(description: "show paywall")

        expect(self.presenter.handle(
            locateOffering: { _ in
                return self.offering
            },
            url: URL(string: "rc://rc-paywall-preview?offering_id=1234&paywall_id=abcd")!,
            viewController: MockViewController { expectation.fulfill() })
        ) == true

        self.wait(for: [expectation], timeout: 0.1)
    }
}

private class MockViewController: UIViewController {
    let present: () -> Void

    init(present: @escaping () -> Void) {
        self.present = present
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        present()
    }

}
