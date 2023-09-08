//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockInternalAPI.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
@testable import RevenueCat

class MockInternalAPI: InternalAPI {

    public convenience init() {
        self.init(backendConfig: MockBackendConfiguration())
    }

    var invokedPostPaywallEvents: Bool = false
    var invokedPostPaywallEventsParameters: [[PaywallStoredEvent]] = []
    var stubbedPostPaywallEventsCompletionResult: BackendError?

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    override func postPaywallEvents(
        events: [PaywallStoredEvent],
        completion: @escaping InternalAPI.ResponseHandler
    ) {
        self.invokedPostPaywallEvents = true
        self.invokedPostPaywallEventsParameters.append(events)

        completion(self.stubbedPostPaywallEventsCompletionResult)
    }

}
