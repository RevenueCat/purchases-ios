//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockASN1ContainerBuilder: ASN1ContainerBuilder {

    var invokedBuild = false
    var invokedBuildCount = 0
    var invokedBuildParameters: (payload: ArraySlice<UInt8>, Void)?
    var invokedBuildParametersList = [(payload: ArraySlice < UInt8>, Void)]()
    var stubbedBuildError: Error?
    var stubbedBuildResult: ASN1Container!

    override func build(fromPayload payload: ArraySlice<UInt8>) throws -> ASN1Container {
        invokedBuild = true
        invokedBuildCount += 1
        invokedBuildParameters = (payload, ())
        invokedBuildParametersList.append((payload, ()))
        if let error = stubbedBuildError {
            throw error
        }
        return stubbedBuildResult
    }
}
