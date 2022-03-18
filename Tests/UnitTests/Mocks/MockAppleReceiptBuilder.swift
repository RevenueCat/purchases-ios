//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockAppleReceiptBuilder: AppleReceiptBuilder {

    var invokedBuild = false
    var invokedBuildCount = 0
    var invokedBuildParameters: ASN1Container?
    var invokedBuildParametersList: [ASN1Container] = []
    var stubbedBuildError: Error?
    var stubbedBuildResult: AppleReceipt!

    override func build(fromContainer container: ASN1Container) throws -> AppleReceipt {
        invokedBuild = true
        invokedBuildCount += 1
        invokedBuildParameters = container
        invokedBuildParametersList.append(container)
        if let error = stubbedBuildError {
            throw error
        }
        return stubbedBuildResult
    }
}
