//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// CustomerCenterViewModelTests.swift
//
//
//  Created by Cesar de la Vega on 11/6/24.
//

#if CUSTOMER_CENTER_ENABLED

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class CustomerCenterViewModelTests: TestCase {

    private let error = TestError(message: "An error occurred")

    private struct TestError: Error, Equatable {
        let message: String
        var localizedDescription: String {
            return message
        }
    }

    func testInitialState() {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil)

        expect(viewModel.state) == .notLoaded
        expect(viewModel.hasSubscriptions) == false
        expect(viewModel.subscriptionsAreFromApple) == false
        expect(viewModel.isLoaded) == false
    }

    func testStateChangeToError() {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil)

        viewModel.setStateForTesting(.error(error))

        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

    func testIsLoaded() {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil)

        expect(viewModel.isLoaded) == false

        viewModel.setStateForTesting(.success)
        viewModel.setConfigurationForTesting(CustomerCenterConfigTestData.customerCenterData)

        expect(viewModel.isLoaded) == true
    }

    func testLoadHasSubscriptionsApple() async {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                customerInfoFetcher: {
            return await CustomerCenterViewModelTests.customerInfoWithAppleSubscriptions
        })

        await viewModel.loadHasSubscriptions()

        expect(viewModel.hasSubscriptions) == true
        expect(viewModel.subscriptionsAreFromApple) == true
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsGoogle() async {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                customerInfoFetcher: {
            return await CustomerCenterViewModelTests.customerInfoWithGoogleSubscriptions
        })

        await viewModel.loadHasSubscriptions()

        expect(viewModel.hasSubscriptions) == true
        expect(viewModel.subscriptionsAreFromApple) == false
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsNonActive() async {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                customerInfoFetcher: {
            return await CustomerCenterViewModelTests.customerInfoWithoutSubscriptions
        })

        await viewModel.loadHasSubscriptions()

        expect(viewModel.hasSubscriptions) == false
        expect(viewModel.subscriptionsAreFromApple) == false
        expect(viewModel.state) == .success
    }

    func testLoadHasSubscriptionsFailure() async {
        let viewModel = CustomerCenterViewModel(customerCenterActionHandler: nil,
                                                customerInfoFetcher: {
            throw TestError(message: "An error occurred")
        })

        await viewModel.loadHasSubscriptions()

        expect(viewModel.hasSubscriptions) == false
        expect(viewModel.subscriptionsAreFromApple) == false
        switch viewModel.state {
        case .error(let stateError):
            expect(stateError as? TestError) == error
        default:
            fail("Expected state to be .error")
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CustomerCenterViewModelTests {

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

#endif

#endif
