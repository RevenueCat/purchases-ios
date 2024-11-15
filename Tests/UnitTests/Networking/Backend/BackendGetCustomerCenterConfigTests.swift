//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetCustomerCenterConfigTests.swift
//
//  Created by Cesar de la Vega on 29/6/24.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetCustomerCenterConfigTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetCustomerCenterConfigCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.customerCenterResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID,
                                                              isAppBackgrounded: false,
                                                              completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    func testGetCustomerCenterConfigPassesLocales() {
        self.createDependencies(localesProvider: MockPreferredLocalesProvider(stubbedLocales: ["en_EN", "es_ES"]))

        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.customerCenterResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID,
                                                              isAppBackgrounded: false,
                                                              completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.httpClient.calls[0].headers["X-Preferred-Locales"]) == "en_EN,es_ES"
    }

    func testGetCustomerCenterConfigCallsHTTPMethodWithRandomDelay() {
        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.customerCenterResponse as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID,
                                                              isAppBackgrounded: true,
                                                              completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == .default
    }

    func testGetCustomerCenterConfigCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.customerCenterResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID, isAppBackgrounded: false) { _ in }
        self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID, isAppBackgrounded: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testRepeatedRequestsLogDebugMessage() {
        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.customerCenterResponse as [String: Any],
                            delay: .milliseconds(10))
        )
        self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID, isAppBackgrounded: false) { _ in }
        self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID, isAppBackgrounded: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))

        self.logger.verifyMessageWasLogged(
            "Network operation '\(GetCustomerCenterConfigOperation.self)' found with the same cache key",
            level: .debug
        )
    }

    func testGetCustomerConfigDoesntCacheForMultipleUserID() {
        let response = MockHTTPClient.Response(statusCode: .success,
                                               response: Self.customerCenterResponse as [String: Any])
        let userID2 = "user_id_2"

        self.httpClient.mock(requestPath: .getCustomerCenterConfig(appUserID: Self.userID), response: response)
        self.httpClient.mock(requestPath: .getCustomerCenterConfig(appUserID: userID2), response: response)

        self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID,
                                                          isAppBackgrounded: false,
                                                          completion: { _ in })
        self.customerCenterConfig.getCustomerCenterConfig(appUserID: userID2,
                                                          isAppBackgrounded: false,
                                                          completion: { _ in })

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetCustomerCenterConfig() throws {
        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.customerCenterResponse as [String: Any])
        )

        let result: Atomic<Result<CustomerCenterConfigResponse, BackendError>?> = nil
        self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID, isAppBackgrounded: false) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let response = try XCTUnwrap(result.value?.value)
        let customerCenter = try XCTUnwrap(response.customerCenter)
        let appearance = try XCTUnwrap(customerCenter.appearance)

        expect(customerCenter.localization.locale) == "en_US"
        expect(customerCenter.localization.localizedStrings).to(haveCount(2))

        expect(appearance.dark.accentColor) == "#ffffff"
        expect(appearance.dark.backgroundColor) == "#000000"
        expect(appearance.dark.textColor) == "#000000"
        expect(appearance.light.accentColor) == "#000000"
        expect(appearance.light.backgroundColor) == "#ffffff"
        expect(appearance.light.textColor) == "#ffffff"

        let screens = try XCTUnwrap(customerCenter.screens)
        expect(screens).to(haveCount(2))

        let noActiveScreen = try XCTUnwrap(customerCenter.screens[
            CustomerCenterConfigData.Screen.ScreenType.noActive.rawValue
        ])
        expect(noActiveScreen.title) == "No subscriptions found"
        expect(noActiveScreen.subtitle) == "We can try checking your account for any previous purchases"

        let managementScreen = try XCTUnwrap(customerCenter.screens[
            CustomerCenterConfigData.Screen.ScreenType.management.rawValue
        ])
        expect(managementScreen.type) == .management
        expect(managementScreen.title) == "How can we help?"

        let noActiveScreenPaths = noActiveScreen.paths
        expect(noActiveScreenPaths).to(haveCount(1))

        let managementPaths = managementScreen.paths
        expect(managementPaths).to(haveCount(4))

        let path1 = managementPaths[0]
        expect(path1.id) == "ownmsldfow"
        expect(path1.title) == "Didn't receive purchase"
        expect(path1.type) == .missingPurchase

        let path2 = managementPaths[1]
        expect(path2.id) == "nwodkdnfaoeb"
        expect(path2.title) == "Request a refund"
        expect(path2.type) == .refundRequest
        let promotionalOffer1 = try XCTUnwrap(path2.promotionalOffer)
        expect(promotionalOffer1.iosOfferId) == "rc-refund-offer"

        let path3 = managementPaths[2]
        expect(path3.id) == "nfoaiodifj9"
        expect(path3.title) == "Change plans"
        expect(path3.type) == .changePlans

        let path4 = managementPaths[3]
        expect(path4.id) == "jnkasldfhas"
        expect(path4.title) == "Cancel subscription"
        expect(path4.type) == .cancel

        let feedbackSurvey = try XCTUnwrap(path4.feedbackSurvey)
        expect(feedbackSurvey.title) == "Why are you cancelling?"
        expect(feedbackSurvey.options).to(haveCount(3))

        let option1 = feedbackSurvey.options[0]
        expect(option1.id) == "iewrthals"
        expect(option1.title) == "Too expensive"
        let promotionalOffer2 = try XCTUnwrap(option1.promotionalOffer)
        expect(promotionalOffer2.iosOfferId) == "rc-cancel-offer"

        let option2 = feedbackSurvey.options[1]
        expect(option2.id) == "qklpadsfj"
        expect(option2.title) == "Don't use the app"
        let promotionalOffer3 = try XCTUnwrap(option2.promotionalOffer)
        expect(promotionalOffer3.iosOfferId) == "rc-cancel-offer"

        let option3 = feedbackSurvey.options[2]
        expect(option3.id) == "jargnapocps"
        expect(option3.title) == "Bought by mistake"
    }

    func testGetCustomerCenterConfigFailSendsNil() {
        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID,
                                                              isAppBackgrounded: false,
                                                              completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testGetCustomerCenterConfigNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getCustomerCenterConfig(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: Self.userID,
                                                              isAppBackgrounded: false,
                                                              completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetCustomerCenterConfigSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: "", isAppBackgrounded: false) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetCustomerCenterConfigCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.customerCenterConfig.getCustomerCenterConfig(appUserID: "", isAppBackgrounded: false) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

}

private extension BackendGetCustomerCenterConfigTests {

    static let customerCenterResponse: [String: Any] = [
        "customer_center": [
            "localization": [
                "locale": "en_US",
                "localized_strings": [
                    "cancel": "Cancel",
                    "back": "Back"
                ] as [String: Any],
                "supported": [
                    "en_US"
                ] as [Any]
            ] as [String: Any],
            "screens": [
                "MANAGEMENT": [
                    "paths": [
                        [
                            "id": "ownmsldfow",
                            "title": "Didn't receive purchase",
                            "type": "MISSING_PURCHASE"
                        ] as [String: Any],
                        [
                            "id": "nwodkdnfaoeb",
                            "promotional_offer": [
                                "ios_offer_id": "rc-refund-offer",
                                "eligible": true,
                                "title": "Wait!",
                                "subtitle": "Here's an offer for you",
                                "product_mapping": [
                                    "product_id": "offer_id"
                                ]
                            ] as [String: Any],
                            "title": "Request a refund",
                            "type": "REFUND_REQUEST"
                        ] as [String: Any],
                        [
                            "id": "nfoaiodifj9",
                            "title": "Change plans",
                            "type": "CHANGE_PLANS"
                        ] as [String: Any],
                        [
                            "feedback_survey": [
                                "options": [
                                    [
                                        "id": "iewrthals",
                                        "promotional_offer": [
                                            "ios_offer_id": "rc-cancel-offer",
                                            "eligible": false,
                                            "title": "Wait!",
                                            "subtitle": "Here's an offer for you",
                                            "product_mapping": [
                                                "product_id": "offer_id"
                                            ]
                                        ] as [String: Any],
                                        "title": "Too expensive"
                                    ] as [String: Any],
                                    [
                                        "id": "qklpadsfj",
                                        "promotional_offer": [
                                            "ios_offer_id": "rc-cancel-offer",
                                            "eligible": false,
                                            "title": "Wait!",
                                            "subtitle": "Here's an offer for you",
                                            "product_mapping": [
                                                "product_id": "offer_id"
                                            ]
                                        ] as [String: Any],
                                        "title": "Don't use the app"
                                    ] as [String: Any],
                                    [
                                        "id": "jargnapocps",
                                        "title": "Bought by mistake"
                                    ] as [String: Any]
                                ] as [Any],
                                "title": "Why are you cancelling?"
                            ] as [String: Any],
                            "id": "jnkasldfhas",
                            "title": "Cancel subscription",
                            "type": "CANCEL"
                        ] as [String: Any]
                    ] as [Any],
                    "title": "How can we help?",
                    "type": "MANAGEMENT"
                ] as [String: Any],
                "NO_ACTIVE": [
                    "paths": [
                        [
                            "id": "9q9719171o",
                            "title": "Check purchases",
                            "type": "MISSING_PURCHASE"
                        ] as [String: Any]
                    ] as [Any],
                    "subtitle": "We can try checking your account for any previous purchases",
                    "title": "No subscriptions found",
                    "type": "NO_ACTIVE"
                ] as [String: Any]
            ] as [String: Any],
            "appearance": [
                "dark": [
                    "accent_color": "#ffffff",
                    "background_color": "#000000",
                    "text_color": "#000000"
                ] as [String: Any],
                "light": [
                    "accent_color": "#000000",
                    "background_color": "#ffffff",
                    "text_color": "#ffffff"
                ] as [String: Any],
                "mode": "CUSTOM"
            ] as [String: Any],
            "support": [
                "email": "support@revenuecat.com"
            ] as [String: Any]
        ] as [String: Any]
    ]

}
