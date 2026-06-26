//
//  MockRemoteConfigSourceProvider.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 26/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
@testable import RevenueCat

final class MockRemoteConfigSourceProvider: RemoteConfigSourceProviderType {

    var stubbedCurrentAPIEndpoint: RemoteConfigEndpoint?
    var currentAPIEndpoint: RemoteConfigEndpoint? { self.stubbedCurrentAPIEndpoint }

    var stubbedCurrentBlobEndpoint: RemoteConfigEndpoint?
    var currentBlobEndpoint: RemoteConfigEndpoint? { self.stubbedCurrentBlobEndpoint }

    private(set) var reportedUnhealthyEndpoints: [RemoteConfigEndpoint] = []
    func reportUnhealthy(_ endpoint: RemoteConfigEndpoint) {
        self.reportedUnhealthyEndpoints.append(endpoint)
    }

    private(set) var restartCallCount = 0
    func restart() {
        self.restartCallCount += 1
    }

}
