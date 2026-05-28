//
//  MockRemoteConfigAPI.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 28/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

@testable import RevenueCat

class MockRemoteConfigAPI: RemoteConfigAPI {

    var stubbedResult: Result<RemoteConfigResponse, BackendError>?
    var invokedGetRemoteConfigCount = 0
    var invokedIsAppBackgrounded: Bool?

    convenience init() {
        self.init(backendConfig: MockBackendConfiguration())
    }

    override func getRemoteConfig(
        isAppBackgrounded: Bool,
        completion: @escaping RemoteConfigResponseHandler
    ) {
        self.invokedGetRemoteConfigCount += 1
        self.invokedIsAppBackgrounded = isAppBackgrounded
        if let result = self.stubbedResult {
            completion(result)
        }
    }

}
