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
    var currentAPISource: RemoteConfigSourceHandle? { self.stubbedCurrentAPISource }

    var stubbedCurrentBlobSource: RemoteConfigSourceHandle?
    var currentBlobSource: RemoteConfigSourceHandle? { self.stubbedCurrentBlobSource }

    private(set) var reportedUnhealthySources: [RemoteConfigSourceHandle] = []
    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        self.reportedUnhealthySources.append(handle)
    }

    private(set) var restartedPurposes: [RemoteConfigSourceHandle.Purpose] = []
    func restart(for purpose: RemoteConfigSourceHandle.Purpose) {
        self.restartedPurposes.append(purpose)
    }

}
