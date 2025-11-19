//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockBackendConfig.swift
//
//  Created by Nacho Soto on 5/18/23.

@testable import RevenueCat

class MockBackendConfiguration: BackendConfiguration {

    init() {
        let systemInfo = MockSystemInfo(finishTransactions: false)
        let mockAPIKey = "mockAPIKey"
        var diagnosticsTracker: DiagnosticsTrackerType?
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            diagnosticsTracker = MockDiagnosticsTracker()
        }
        let httpClient = MockHTTPClient(apiKey: mockAPIKey,
                                        systemInfo: systemInfo,
                                        eTagManager: MockETagManager(),
                                        diagnosticsTracker: diagnosticsTracker,
                                        requestTimeout: 7)

        super.init(
            httpClient: httpClient,
            operationDispatcher: MockOperationDispatcher(),
            operationQueue: Backend.QueueProvider.createBackendQueue(),
            diagnosticsQueue: Backend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: systemInfo,
            offlineCustomerInfoCreator: MockOfflineCustomerInfoCreator(),
            dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate)
        )
    }

}

extension MockBackendConfiguration: @unchecked Sendable {}
