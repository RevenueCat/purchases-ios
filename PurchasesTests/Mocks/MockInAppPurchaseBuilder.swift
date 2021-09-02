//
// Created by Andrés Boedo on 8/10/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockInAppPurchaseBuilder: InAppPurchaseBuilder {

    var invokedBuild = false
    var invokedBuildCount = 0
    var invokedBuildParameters: (container: ASN1Container, Void)?
    var invokedBuildParametersList = [(container: ASN1Container, Void)]()
    var stubbedBuildError: Error?
    var stubbedBuildResult: InAppPurchase!

    override func build(fromContainer container: ASN1Container) throws -> InAppPurchase {
        invokedBuild = true
        invokedBuildCount += 1
        invokedBuildParameters = (container, ())
        invokedBuildParametersList.append((container, ()))
        if let error = stubbedBuildError {
            throw error
        }
        return stubbedBuildResult
    }
}
