//
//  MockAttributionDataMigrator.swift
//  PurchasesTests
//
//  Created by César de la Vega on 7/2/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

// swiftlint:disable line_length
// swiftlint:disable identifier_name
class MockAttributionDataMigrator: AttributionDataMigrator {

    var invokedConvertAttributionDataToSubscriberAttributes = false
    var invokedConvertAttributionDataToSubscriberAttributesCount = 0
    var invokedConvertAttributionDataToSubscriberAttributesParameters: (attributionData: [String: Any], network: Int)?
    var invokedConvertAttributionDataToSubscriberAttributesParametersList = [(attributionData: [String: Any], network: Int)]()
    var stubbedConvertAttributionDataToSubscriberAttributesResult: [String: String]! = [:]

    override func convertToSubscriberAttributes(
        attributionData: [String: Any], network: Int
    ) -> [String: String] {
        invokedConvertAttributionDataToSubscriberAttributes = true
        invokedConvertAttributionDataToSubscriberAttributesCount += 1
        invokedConvertAttributionDataToSubscriberAttributesParameters = (attributionData, network)
        invokedConvertAttributionDataToSubscriberAttributesParametersList.append((attributionData, network))
        return stubbedConvertAttributionDataToSubscriberAttributesResult
    }
}
