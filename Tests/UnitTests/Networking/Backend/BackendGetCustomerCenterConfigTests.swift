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
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == Delay.none
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
        expect(self.httpClient.calls[0].headers["X-Supported-Locales"]) == "en_EN,es_ES"
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

        expect(customerCenter.locale) == "en_US"
        expect(appearance.dark.accentColor) == "#ffffff"
        expect(appearance.dark.backgroundColor) == "#000000"
        expect(appearance.dark.textColor) == "#000000"
        expect(appearance.light.accentColor) == "#000000"
        expect(appearance.light.backgroundColor) == "#ffffff"
        expect(appearance.light.textColor) == "#ffffff"
        expect(appearance.mode) == "CUSTOM"

        let paths = try XCTUnwrap(customerCenter.paths)
        expect(paths).to(haveCount(4))

        let path1 = paths[0]
        expect(path1.id) == "ownmsldfow"
        expect(path1.title) == "Didn't receive purchase"
        expect(path1.type) == .missingPurchase

        let path2 = paths[1]
        expect(path2.id) == "nwodkdnfaoeb"
        expect(path2.title) == "Request a refund"
        expect(path2.type) == .refundRequest

        let path3 = paths[2]
        expect(path3.id) == "nfoaiodifj9"
        expect(path3.title) == "Change plans"
        expect(path3.type) == .changePlans

        let path4 = paths[3]
        expect(path4.id) == "jnkasldfhas"
        expect(path4.title) == "Cancel subscription"
        expect(path4.type) == .cancel

        let feedbackSurvey = try XCTUnwrap(path4.feedbackSurvey)
        expect(feedbackSurvey.title) == "Why are you cancelling?"
        expect(feedbackSurvey.options).to(haveCount(3))

        let option1 = feedbackSurvey.options[0]
        expect(option1.id) == "iewrthals"
        expect(option1.title) == "Too expensive"

        let option2 = feedbackSurvey.options[1]
        expect(option2.id) == "qklpadsfj"
        expect(option2.title) == "Don't use the app"

        let option3 = feedbackSurvey.options[2]
        expect(option3.id) == "jargnapocps"
        expect(option3.title) == "Bought by mistake"

        let screens = try XCTUnwrap(customerCenter.screens)
        expect(screens).to(haveCount(2))

        let screen1 = screens[0]
        expect(screen1.type) == .management
        expect(screen1.title) == "How can we help?"

        let screen2 = screens[1]
        expect(screen2.type) == .noActive
        expect(screen2.title) == "No subscriptions found"
        expect(screen2.subtitle) == "We can try checking your account for any previous purchases"
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

    static let customerCenterResponse: [String: Any?] = [
        "customer_center": [
            "appearance": [
                "dark": [
                    "accent_color": "#ffffff",
                    "background_color": "#000000",
                    "text_color": "#000000"
                ],
                "light": [
                    "accent_color": "#000000",
                    "background_color": "#ffffff",
                    "text_color": "#ffffff"
                ],
                "mode": "CUSTOM"
            ],
            "locale": "en_US",
            "paths": [
                [
                    "id": "ownmsldfow",
                    "title": "Didn't receive purchase",
                    "type": "MISSING_PURCHASE"
                ],
                [
                    "id": "nwodkdnfaoeb",
                    "title": "Request a refund",
                    "type": "REFUND_REQUEST"
                ],
                [
                    "id": "nfoaiodifj9",
                    "title": "Change plans",
                    "type": "CHANGE_PLANS"
                ],
                [

                    "id": "jnkasldfhas",
                    "title": "Cancel subscription",
                    "type": "CANCEL",
                    "feedback_survey": [
                        "id": "jlajsdfkal",
                        "options": [
                            [
                                "id": "iewrthals",
                                "title": "Too expensive"
                            ],
                            [
                                "id": "qklpadsfj",
                                "title": "Don't use the app"
                            ],
                            [
                                "id": "jargnapocps",
                                "title": "Bought by mistake"
                            ]
                        ],
                        "title": "Why are you cancelling?"
                    ]
                ]
            ],
            "screens": [
                [
                    "title": "How can we help?",
                    "type": "MANAGEMENT"
                ],
                [
                    "subtitle": "We can try checking your account for any previous purchases",
                    "title": "No subscriptions found",
                    "type": "NO_ACTIVE"
                ]
            ],
            "support_email": "support@revenuecat.com"
        ]
    ]

}
