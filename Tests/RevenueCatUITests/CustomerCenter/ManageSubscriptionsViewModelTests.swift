//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// ManageSubscriptionsViewModelTests.swift
//
//
//  Created by Cesar de la Vega on 11/6/24.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import StoreKit
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class ManageSubscriptionsViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = ManageSubscriptionsViewModel()

        expect(viewModel.state) == .notLoaded
        expect(viewModel.subscriptionInformation).to(beNil())
        expect(viewModel.refundRequestStatusMessage).to(beNil())
        expect(viewModel.configuration).to(beNil())
        expect(viewModel.showRestoreAlert) == false
        expect(viewModel.isLoaded) == false
    }

    func testStateChangeToError() {
        let viewModel = ManageSubscriptionsViewModel()

        viewModel.state = .error(error)

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

    func testIsLoaded() {
        let viewModel = ManageSubscriptionsViewModel()

        expect(viewModel.isLoaded) == false

        viewModel.state = .success

        expect(viewModel.isLoaded) == true
    }

    func testLoadScreenSuccess() async {
        let viewModel = ManageSubscriptionsViewModel(purchasesProvider: MockManageSubscriptionsPurchases())

        await viewModel.loadScreen()

        expect(viewModel.subscriptionInformation).toNot(beNil())
        expect(viewModel.configuration).toNot(beNil())
        expect(viewModel.state) == .success

        expect(viewModel.subscriptionInformation?.title) == "title"
        expect(viewModel.subscriptionInformation?.durationTitle) == "month"
        expect(viewModel.subscriptionInformation?.price) == "$2.99"
        expect(viewModel.subscriptionInformation?.nextRenewalString) == "Apr 12, 2062"
        expect(viewModel.subscriptionInformation?.productIdentifier) == "com.revenuecat.product"
    }

    func testLoadScreenNoActiveSubscription() async {
        let viewModel = ManageSubscriptionsViewModel(purchasesProvider: MockManageSubscriptionsPurchases(
            customerInfo: CustomerCenterViewModelTests.customerInfoWithoutSubscriptions
        ))

        await viewModel.loadScreen()

        expect(viewModel.subscriptionInformation).to(beNil())
        expect(viewModel.state) == .error(CustomerCenterError.couldNotFindSubscriptionInformation)
    }

    func testLoadScreenFailure() async {
        let viewModel = ManageSubscriptionsViewModel(purchasesProvider: MockManageSubscriptionsPurchases(
            customerInfoError: error
        ))

        await viewModel.loadScreen()

        expect(viewModel.subscriptionInformation).to(beNil())
        expect(viewModel.state) == .error(error)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class MockManageSubscriptionsPurchases: ManageSubscriptionsPurchaseType {

    let customerInfo: CustomerInfo?
    let customerInfoError: Error?
    let productsShouldFail: Bool
    let showManageSubscriptionsError: Error?
    let beginRefundShouldFail: Bool

    init(
        customerInfo: CustomerInfo? = nil,
        customerInfoError: Error? = nil,
        productsShouldFail: Bool = false,
        showManageSubscriptionsError: Error? = nil,
        beginRefundShouldFail: Bool = false
    ) {
        self.customerInfo = customerInfo
        self.customerInfoError = customerInfoError
        self.productsShouldFail = productsShouldFail
        self.showManageSubscriptionsError = showManageSubscriptionsError
        self.beginRefundShouldFail = beginRefundShouldFail
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        if let customerInfoError {
            throw customerInfoError
        }
        if let customerInfo {
            return customerInfo
        }
        return CustomerCenterViewModelTests.customerInfoWithAppleSubscriptions
    }

    func products(_ productIdentifiers: [String]) async -> [RevenueCat.StoreProduct] {
        if productsShouldFail {
            return []
        }
        let product = await CustomerCenterViewModelTests.createMockProduct()
        return [product]
    }

    func showManageSubscriptions() async throws {
        if let showManageSubscriptionsError {
            throw showManageSubscriptionsError
        }
    }

    func beginRefundRequest(forProduct productID: String) async throws -> RevenueCat.RefundRequestStatus {
        if beginRefundShouldFail {
            return .error
        }
        return .success
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterViewModelTests {

    static func createMockProduct() -> StoreProduct {
        // Using SK1 products because they can be mocked, but CustomerCenterViewModel
        // works with generic `StoreProduct`s regardless of what they contain
        return StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "identifier",
                                                       mockLocalizedTitle: "title"))
    }

    static let customerInfoWithAppleSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2062-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "2022-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "2022-04-12T00:03:28Z",
                        "store": "app_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                    "premium": {
                        "expires_date": "2062-04-12T00:03:35Z",
                        "product_identifier": "com.revenuecat.product",
                        "purchase_date": "2022-04-12T00:03:28Z"
                    }
                }
            }
        }
        """
        )
    }()

    static let customerInfoWithGoogleSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2062-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "2022-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "2022-04-12T00:03:28Z",
                        "store": "play_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                    "premium": {
                        "expires_date": "2062-04-12T00:03:35Z",
                        "product_identifier": "com.revenuecat.product",
                        "purchase_date": "2022-04-12T00:03:28Z"
                    }
                }
            }
        }
        """
        )
    }()

    static let customerInfoWithoutSubscriptions: CustomerInfo = {
        return .decode(
        """
        {
            "schema_version": "4",
            "request_date": "2022-03-08T17:42:58Z",
            "request_date_ms": 1646761378845,
            "subscriber": {
                "first_seen": "2022-03-08T17:42:58Z",
                "last_seen": "2022-03-08T17:42:58Z",
                "management_url": "https://apps.apple.com/account/subscriptions",
                "non_subscriptions": {
                },
                "original_app_user_id": "$RCAnonymousID:5b6fdbac3a0c4f879e43d269ecdf9ba1",
                "original_application_version": "1.0",
                "original_purchase_date": "2022-04-12T00:03:24Z",
                "other_purchases": {
                },
                "subscriptions": {
                    "com.revenuecat.product": {
                        "billing_issues_detected_at": null,
                        "expires_date": "2000-04-12T00:03:35Z",
                        "grace_period_expires_date": null,
                        "is_sandbox": true,
                        "original_purchase_date": "1999-04-12T00:03:28Z",
                        "period_type": "intro",
                        "purchase_date": "1999-04-12T00:03:28Z",
                        "store": "play_store",
                        "unsubscribe_detected_at": null
                    },
                },
                "entitlements": {
                    "premium": {
                        "expires_date": "2000-04-12T00:03:35Z",
                        "product_identifier": "com.revenuecat.product",
                        "purchase_date": "1999-04-12T00:03:28Z"
                    }
                }
            }
        }
        """
        )
    }()

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private class MockSK1Product: SK1Product {
    var mockProductIdentifier: String
    var mockLocalizedTitle: String

    init(mockProductIdentifier: String, mockLocalizedTitle: String) {
        self.mockProductIdentifier = mockProductIdentifier
        self.mockLocalizedTitle = mockLocalizedTitle

        super.init()
    }

    override var productIdentifier: String {
        return self.mockProductIdentifier
    }

    var mockSubscriptionGroupIdentifier: String?
    override var subscriptionGroupIdentifier: String? {
        return self.mockSubscriptionGroupIdentifier
    }

    var mockPriceLocale: Locale?
    override var priceLocale: Locale {
        return mockPriceLocale ?? Locale(identifier: "en_US")
    }

    var mockPrice: Decimal?
    override var price: NSDecimalNumber {
        return (mockPrice ?? 2.99) as NSDecimalNumber
    }

    override var localizedTitle: String {
        return self.mockLocalizedTitle
    }

    override var introductoryPrice: SKProductDiscount? {
        return mockDiscount
    }

    private var _mockDiscount: Any?

    var mockDiscount: SKProductDiscount? {
        // swiftlint:disable:next force_cast
        get { return self._mockDiscount as! SKProductDiscount? }
        set { self._mockDiscount = newValue }
    }

    override var discounts: [SKProductDiscount] {
        return self.mockDiscount.map { [$0] } ?? []
    }

    private lazy var _mockSubscriptionPeriod: Any? = {
        return SKProductSubscriptionPeriod(numberOfUnits: 1, unit: SKProduct.PeriodUnit.month)
    }()

    var mockSubscriptionPeriod: SKProductSubscriptionPeriod? {
        // swiftlint:disable:next force_cast
        get { self._mockSubscriptionPeriod as! SKProductSubscriptionPeriod? }
        set { self._mockSubscriptionPeriod = newValue }
    }

    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return mockSubscriptionPeriod
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension SKProductSubscriptionPeriod {
    convenience init(numberOfUnits: Int,
                     unit: SK1Product.PeriodUnit) {
        self.init()
        self.setValue(numberOfUnits, forKey: "numberOfUnits")
        self.setValue(unit.rawValue, forKey: "unit")
    }
}

#endif
