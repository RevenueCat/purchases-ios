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

    var stubbedCurrentAPISource: RemoteConfigSourceHandle?
    var stubbedCurrentBlobSource: RemoteConfigSourceHandle?

    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle? {
        switch purpose {
        case .api: return self.stubbedCurrentAPISource
        case .blob: return self.stubbedCurrentBlobSource
        }
    }

    private(set) var reportedUnhealthySources: [RemoteConfigSourceHandle] = []
    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        self.reportedUnhealthySources.append(handle)
    }

    private(set) var restartedPurposes: [RemoteConfigSourceHandle.Purpose] = []
    func restart(for purpose: RemoteConfigSourceHandle.Purpose) {
        self.restartedPurposes.append(purpose)
    }

    private(set) var restartIfExhaustedPurposes: [RemoteConfigSourceHandle.Purpose] = []
    var stubbedRestartIfExhaustedResult = false
    func restartIfExhausted(for purpose: RemoteConfigSourceHandle.Purpose) -> Bool {
        self.restartIfExhaustedPurposes.append(purpose)
        return self.stubbedRestartIfExhaustedResult
    }

}
