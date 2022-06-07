//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionPosterTests.swift
//  PurchasesTests
//
//  Created by César de la Vega on 7/17/20.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class AttributionPosterTests: BaseAttributionPosterTests {

    func testPostAttributionDataSkipsIfAlreadySent() {
        let userID = "userID"

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: userID)

        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1
    }

    func testPostAttributionDataDoesntSkipIfNetworkChanged() {
        let userID = "userID"
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())
        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .facebook,
                               networkUserId: userID)
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

    func testPostAttributionDataDoesntSkipIfDifferentUserIdButSameNetwork() {
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: "attributionUser1")
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .adjust,
                               networkUserId: "attributionUser2")
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

}
