//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigDataTests.swift
//
//  Created by Cesar de la Vega on 8/7/24.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class CustomerCenterConfigDataTests: TestCase {

    func testCustomerCenterConfigDataConversion() {
        let mockResponse = CustomerCenterConfigResponse(
            customerCenter: .init(
                appearance: .init(
                    mode: "CUSTOM",
                    light: .init(accentColor: "#FFFFFF", backgroundColor: "#000000", textColor: "#FF0000"),
                    dark: .init(accentColor: "#000000", backgroundColor: "#FFFFFF", textColor: "#00FF00")
                ),
                screens: [
                    "MANAGEMENT": .init(
                        title: "Management Screen",
                        type: .management,
                        subtitle: "Manage your account",
                        paths: [
                            .init(
                                id: "path1",
                                title: "Path 1",
                                type: .missingPurchase,
                                promotionalOffer: nil,
                                feedbackSurvey: nil
                            ),
                            .init(
                                id: "path2",
                                title: "Path 2",
                                type: .cancel,
                                promotionalOffer: .init(iosOfferId: "offer_id", eligible: true),
                                feedbackSurvey: nil
                            ),
                            .init(
                                id: "path3",
                                title: "Path 3",
                                type: .changePlans,
                                promotionalOffer: nil,
                                feedbackSurvey: .init(title: "survey title",
                                                      options: [
                                                        .init(id: "id_1",
                                                              title: "option 1",
                                                              promotionalOffer: .init(iosOfferId: "offer_id_1"))
                                                      ])
                            )
                        ]
                    )
                ],
                localization: .init(locale: "en_US", localizedStrings: ["key": "value"]),
                support: .init(email: "support@example.com")
            )
        )

        let configData = CustomerCenterConfigData(from: mockResponse)

        expect(configData.localization.locale) == "en_US"
        expect(configData.localization.localizedStrings["key"]) == "value"

        expect(configData.appearance.mode.rawValue) == "CUSTOM"
        expect(configData.appearance.light.accentColor) == "#FFFFFF"
        expect(configData.appearance.light.backgroundColor) == "#000000"
        expect(configData.appearance.light.textColor) == "#FF0000"
        expect(configData.appearance.dark.accentColor) == "#000000"
        expect(configData.appearance.dark.backgroundColor) == "#FFFFFF"
        expect(configData.appearance.dark.textColor) == "#00FF00"

        expect(configData.screens.count) == 1
        expect(configData.screens.first?.type.rawValue) == "MANAGEMENT"
        expect(configData.screens.first?.title) == "Management Screen"
        expect(configData.screens.first?.subtitle) == "Manage your account"
        expect(configData.screens.first?.paths.count) == 3

        let paths = configData.screens.first?.paths

        expect(paths?[0].id) == "path1"
        expect(paths?[0].title) == "Path 1"
        expect(paths?[0].type.rawValue) == "MISSING_PURCHASE"
        expect(paths?[0].detail).to(beNil())

        expect(paths?[1].id) == "path2"
        expect(paths?[1].title) == "Path 2"
        expect(paths?[1].type.rawValue) == "CANCEL"
        if case let .promotionalOffer(promotionalOffer) = paths?[1].detail {
            expect(promotionalOffer.iosOfferId) == "offer_id"
            expect(promotionalOffer.eligible).to(beTrue())
        } else {
            fail("Expected promotionalOffer detail")
        }

        expect(paths?[2].id) == "path3"
        expect(paths?[2].title) == "Path 3"
        expect(paths?[2].type.rawValue) == "CHANGE_PLANS"
        if case let .feedbackSurvey(feedbackSurvey) = paths?[2].detail {
            expect(feedbackSurvey.title) == "survey title"
            expect(feedbackSurvey.options.count) == 1
            expect(feedbackSurvey.options.first?.id) == "id_1"
            expect(feedbackSurvey.options.first?.title) == "option 1"
        } else {
            fail("Expected feedbackSurvey detail")
        }
    }
}
