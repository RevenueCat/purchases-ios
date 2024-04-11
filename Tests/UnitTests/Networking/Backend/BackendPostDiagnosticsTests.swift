//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostDiagnosticsTests.swift
//
//  Created by Cesar de la Vega on 10/4/24.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendPostDiagnosticsTests: TestCase {

    private(set) var systemInfo: SystemInfo!
    private(set) var httpClient: MockHTTPClient!
    private(set) var operationDispatcher: MockOperationDispatcher!
    private(set) var mockProductEntitlementMappingFetcher: MockProductEntitlementMappingFetcher!
    private(set) var mockOfflineCustomerInfoCreator: MockOfflineCustomerInfoCreator!
    private(set) var mockPurchasedProductsFetcher: MockPurchasedProductsFetcher!
    private(set) var backend: Backend!
    private(set) var api: DiagnosticsAPI!

    static let apiKey = "asharedsecret"

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.createDependencies()
    }

    final func createDependencies(dangerousSettings: DangerousSettings? = nil) {
        self.systemInfo =  SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            storefrontProvider: MockStorefrontProvider(),
            responseVerificationMode: self.responseVerificationMode,
            dangerousSettings: .init()
        )
        self.httpClient = self.createClient()
        self.operationDispatcher = MockOperationDispatcher()
        self.mockProductEntitlementMappingFetcher = MockProductEntitlementMappingFetcher()
        self.mockOfflineCustomerInfoCreator = MockOfflineCustomerInfoCreator()
        self.mockPurchasedProductsFetcher = MockPurchasedProductsFetcher()

        let backendConfig = BackendConfiguration(
            httpClient: self.httpClient,
            operationDispatcher: self.operationDispatcher,
            operationQueue: MockBackend.QueueProvider.createBackendQueue(),
            diagnosticsQueue: MockBackend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: self.systemInfo,
            offlineCustomerInfoCreator: self.mockOfflineCustomerInfoCreator,
            dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate)
        )

        self.api = DiagnosticsAPI(backendConfig: backendConfig)
    }

    func createClient() -> MockHTTPClient {
        let eTagManager = MockETagManager()

        return MockHTTPClient(apiKey: Self.apiKey,
                              systemInfo: self.systemInfo,
                              eTagManager: eTagManager,
                              sourceTestFile: #file)
    }

    func testPostDiagnosticsCallsHttpClient() throws {
        let event1 = DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                      properties: ["key": AnyEncodable("value")],
                                      timestamp: Date())

        let event2 = DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                      properties: ["key": AnyEncodable("value")],
                                      timestamp: Date())

        self.httpClient.mock(
            requestPath: .postDiagnostics,
            response: .init(statusCode: .success)
        )

        waitUntil { completed in
            self.api.postDiagnostics(items: [event1, event2]) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

}

extension BackendPostDiagnosticsTests {

    private var responseVerificationMode: Signing.ResponseVerificationMode {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            return Signing.verificationMode(with: .disabled)
        } else {
            return .disabled
        }
    }

}
