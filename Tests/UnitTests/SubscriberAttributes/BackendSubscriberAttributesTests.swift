//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendSubscriberAttributesTestBase.swift
//
//  Created by Joshua Liebowitz on 3/28/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendSubscriberAttributesTests: TestCase {

    let appUserID = "abc123"
    let referenceDate = Date(timeIntervalSinceReferenceDate: 700000000) // 2023-03-08 20:26:40
    let receipt = EncodedAppleReceipt.receipt("an awesome receipt".data(using: String.Encoding.utf8)!)

    var subscriberAttribute1: SubscriberAttribute!
    var subscriberAttribute2: SubscriberAttribute!
    var mockHTTPClient: MockHTTPClient!
    var backend: Backend!

    private var dateProvider: MockDateProvider!
    private var mockETagManager: MockETagManager!

    private static let apiKey = "the api key"

    let validSubscriberResponse: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2017-08-30T02:40:36Z"
                ]
            ]
        ] as [String: Any]
    ]

    private let systemInfo = SystemInfo(
        platformInfo: .init(flavor: "Unity", version: "2.3.3"),
        finishTransactions: true,
        storefrontProvider: MockStorefrontProvider()
    )

    override func setUpWithError() throws {
        mockHTTPClient = self.createClient()
        dateProvider = MockDateProvider(stubbedNow: self.referenceDate)
        let attributionFetcher = AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: self.systemInfo)

        let config = BackendConfiguration(httpClient: self.mockHTTPClient,
                                          operationDispatcher: MockOperationDispatcher(),
                                          operationQueue: MockBackend.QueueProvider.createBackendQueue(),
                                          systemInfo: self.systemInfo,
                                          offlineCustomerInfoCreator: MockOfflineCustomerInfoCreator(),
                                          dateProvider: self.dateProvider)

        self.backend = Backend(backendConfig: config, attributionFetcher: attributionFetcher)

        subscriberAttribute1 = SubscriberAttribute(withKey: "a key",
                                                   value: "a value",
                                                   dateProvider: dateProvider)

        subscriberAttribute2 = SubscriberAttribute(withKey: "another key",
                                                   value: "another value",
                                                   dateProvider: dateProvider)

        try super.setUpWithError()
    }

    // MARK: PostReceipt with subscriberAttributes

    func testPostReceiptWithSubscriberAttributesSendsThemCorrectly() throws {
        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        backend.post(receipt: self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: self.appUserID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: subscriberAttributesByKey,
                        storefront: nil,
                        source: .init(isRestore: false, initiationSource: .restore)
                     ),
                     observerMode: false) { _ in }

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
    }

    func testPostReceiptWithAdServicesToken() throws {
        let token = "token"

        waitUntil { completion in
            self.backend.post(receipt: self.receipt,
                              productData: nil,
                              transactionData: .init(
                                 appUserID: self.appUserID,
                                 presentedOfferingID: nil,
                                 unsyncedAttributes: [:],
                                 aadAttributionToken: token,
                                 storefront: nil,
                                 source: .init(isRestore: false, initiationSource: .restore)
                              ),
                              observerMode: false) { _ in
                completion()
            }
        }

        expect(self.mockHTTPClient.calls).to(haveCount(1))
    }

    func testPostReceiptWithSubscriberAttributesReturnsBadJson() throws {
        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        let receivedResult: Atomic<Result<CustomerInfo, BackendError>?> = nil

        // No mocked response, the default response is an empty 200.

        backend.post(receipt: self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: self.appUserID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: subscriberAttributesByKey,
                        storefront: nil,
                        source: .init(isRestore: false, initiationSource: .queue)
                     ),
                     observerMode: false) {
            receivedResult.value = $0
        }

        expect(receivedResult.value).toEventuallyNot(beNil())
        expect(receivedResult.value).to(beFailure())

        let error = try XCTUnwrap(receivedResult.value?.error)
        guard case .networkError(.decoding) = error else {
            fail("Unexpected error: \(error)")
            return
        }
    }

    func testPostReceiptWithoutSubscriberAttributesSkipsThem() throws {
        backend.post(receipt: self.receipt,
                     productData: nil,
                     transactionData: .init(
                        appUserID: self.appUserID,
                        presentedOfferingID: nil,
                        unsyncedAttributes: nil,
                        storefront: nil,
                        source: .init(isRestore: false, initiationSource: .purchase)
                     ),
                     observerMode: false) { _ in }

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
    }

    func testPostReceiptWithSubscriberAttributesPassesCustomerInfoIfStatusCodeIsSuccess() throws {
        let attributeError = "email is not in valid format"

        let attributeErrors: [String: Any] = [
            ErrorDetails.attributeErrorsKey: [
                [
                    "key_name": "$email",
                    "message": attributeError
                ]
            ],
            "code": BackendErrorCode.invalidSubscriberAttributes.rawValue,
            "message": "Some subscriber attributes keys were unable to be saved."
        ]

        self.mockHTTPClient.mock(
            requestPath: .postReceiptData,
            response: .init(
                statusCode: .success,
                response: self.validSubscriberResponse + [ErrorDetails.attributeErrorsResponseKey: attributeErrors]
            )
        )

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        let receivedCustomerInfo: CustomerInfo? = waitUntilValue { completion in
            self.backend.post(
                receipt: self.receipt,
                productData: nil,
                transactionData: .init(
                    appUserID: self.appUserID,
                    presentedOfferingID: nil,
                    unsyncedAttributes: subscriberAttributesByKey,
                    storefront: nil,
                    source: .init(isRestore: false, initiationSource: .queue)
                ),
                observerMode: false
            ) { result in
                completion(result.value)
            }
        }

        expect(self.mockHTTPClient.calls).to(haveCount(1))

        let loggedMessages = self.logger.messages.map(\.message)

        expect(receivedCustomerInfo) == CustomerInfo(testData: self.validSubscriberResponse)
        expect(loggedMessages).to(
            containElementSatisfying {
                $0.localizedCaseInsensitiveContains(ErrorCode.invalidSubscriberAttributesError.description)
            },
            description: "ErrorCode description must have been logged"
        )
        expect(loggedMessages).to(
            containElementSatisfying { $0.localizedCaseInsensitiveContains(attributeError.description) },
            description: "Attribute errors must have been logged. Logged messages: \(loggedMessages)"
        )
    }

    func testPostReceiptWithSubscriberAttributesPassesErrorIfStatusCodeIsNotSuccess() throws {
        let errorResponse: ErrorResponse = .init(
            code: .invalidSubscriberAttributes,
            originalCode: BackendErrorCode.invalidSubscriberAttributes.rawValue,
            message: "Some subscriber attributes keys were unable to be saved.",
            attributeErrors: [ "$email": "email is not in valid format"]
        )

        let networkError: NetworkError = .errorResponse(errorResponse, .invalidRequest)

        self.mockHTTPClient.mock(
            requestPath: .postReceiptData,
            response: .init(error: networkError)
        )

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        let receivedError: BackendError? = waitUntilValue { completion in
            self.backend.post(
                receipt: self.receipt,
                productData: nil,
                transactionData: .init(
                    appUserID: self.appUserID,
                    presentedOfferingID: nil,
                    unsyncedAttributes: subscriberAttributesByKey,
                    storefront: nil,
                    source: .init(isRestore: false, initiationSource: .restore)
                ),
                observerMode: false
            ) { result in
                completion(result.error)
            }
        }

        expect(self.mockHTTPClient.calls).to(haveCount(1))

        expect(receivedError) == .networkError(networkError)
    }

    // MARK: PostSubscriberAttributes

    func testPostSubscriberAttributesSendsRightParameters() throws {
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (_: Error!) in })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
    }

    func testPostSubscriberAttributesCallsCompletionInSuccessCase() {
        var completionCallCount = 0

        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (_: Error!) in
            completionCallCount += 1
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))
    }

    func testPostSubscriberAttributesCallsCompletionInNetworkErrorCase() throws {
        var completionCallCount = 0
        let underlyingError: NetworkError = .networkError(NSError(domain: "domain", code: 0, userInfo: nil))

        self.mockHTTPClient.mock(
            requestPath: .postSubscriberAttributes(appUserID: appUserID),
            response: .init(error: underlyingError)
        )

        var receivedError: BackendError?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { error in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))

        expect(receivedError?.successfullySynced) == false
        expect(receivedError) == .networkError(underlyingError)
    }

    func testPostSubscriberAttributesSendsAttributesErrorsIfAny() throws {
        var completionCallCount = 0

        let error: NetworkError = .errorResponse(
            ErrorResponse.from([
                ErrorDetails.attributeErrorsKey: [
                    [
                        "key_name": "$some_attribute",
                        "message": "wasn't valid"
                    ]
                ]
            ]),
            503
        )

        self.mockHTTPClient.mock(
            requestPath: .postSubscriberAttributes(appUserID: appUserID),
            response: .init(error: error)
        )

        var receivedError: BackendError?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: {
            completionCallCount += 1
            receivedError = $0
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toEventuallyNot(beNil())

        expect(receivedError) == .networkError(error)
    }

    func testPostSubscriberAttributesCallsCompletionWithErrorInBadRequestCase() throws {
        var completionCallCount = 0

        let mockedError: NetworkError = .unexpectedResponse(nil)

        mockHTTPClient.mock(requestPath: .postSubscriberAttributes(appUserID: appUserID),
                            response: .init(error: mockedError))

        var receivedError: BackendError?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { error in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())

        expect(receivedError) == .networkError(mockedError)
    }

    func testPostSubscriberAttributesNoOpIfAttributesAreEmpty() {
        var completionCallCount = 0
        backend.post(subscriberAttributes: [:],
                     appUserID: appUserID,
                     completion: { (_: Error!) in
            completionCallCount += 1

        })
        expect(self.mockHTTPClient.calls).to(beEmpty())
    }

    func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

    final func createClient(_ file: StaticString) -> MockHTTPClient {
        self.mockETagManager = MockETagManager()

        return MockHTTPClient(apiKey: Self.apiKey,
                              systemInfo: self.systemInfo,
                              eTagManager: self.mockETagManager,
                              sourceTestFile: file)
    }

}
