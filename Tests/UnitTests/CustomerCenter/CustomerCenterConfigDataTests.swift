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

#if CUSTOMER_CENTER_ENABLED

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class CustomerCenterConfigDataTests: TestCase {

    func testCustomerCenterConfigDataConversion() throws {
        let mockResponse = CustomerCenterConfigResponse(
            customerCenter: .init(
                appearance: .init(
                    light: .init(accentColor: "#A3F9B5",
                                 textColor: "#7B2D26",
                                 backgroundColor: "#E1C6FF",
                                 buttonTextColor: "#0D3F4F",
                                 buttonBackgroundColor: "#FFA07A"),
                    dark: .init(accentColor: "#5D3FD3",
                                textColor: "#98FB98",
                                backgroundColor: "#2F4F4F",
                                buttonTextColor: "#FFD700",
                                buttonBackgroundColor: "#8B4513")
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
                                promotionalOffer: .init(iosOfferId: "offer_id",
                                                        eligible: true,
                                                        title: "Wait!",
                                                        subtitle: "Before you go"),
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
                                                              promotionalOffer: .init(iosOfferId: "offer_id_1",
                                                                                      eligible: true,
                                                                                      title: "Wait!",
                                                                                      subtitle: "Before you go"))
                                                      ])
                            )
                        ]
                    )
                ],
                localization: .init(locale: "en_US", localizedStrings: ["key": "value"]),
                support: .init(email: "support@example.com")
            ),
            lastPublishedAppVersion: "1.2.3"
        )

        let configData = CustomerCenterConfigData(from: mockResponse)

        expect(configData.localization.locale) == "en_US"
        expect(configData.localization.localizedStrings["key"]) == "value"

        expect(configData.appearance.accentColor.light!.stringRepresentation) == "#A3F9B5"
        expect(configData.appearance.accentColor.dark!.stringRepresentation) == "#5D3FD3"
        expect(configData.appearance.backgroundColor.light!.stringRepresentation) == "#E1C6FF"
        expect(configData.appearance.backgroundColor.dark!.stringRepresentation) == "#2F4F4F"
        expect(configData.appearance.textColor.light!.stringRepresentation) == "#7B2D26"
        expect(configData.appearance.textColor.dark!.stringRepresentation) == "#98FB98"
        expect(configData.appearance.buttonTextColor.light!.stringRepresentation) == "#0D3F4F"
        expect(configData.appearance.buttonTextColor.dark!.stringRepresentation) == "#FFD700"
        expect(configData.appearance.buttonBackgroundColor.light!.stringRepresentation) == "#FFA07A"
        expect(configData.appearance.buttonBackgroundColor.dark!.stringRepresentation) == "#8B4513"

        expect(configData.screens.count) == 1
        let managementScreen = try XCTUnwrap(configData.screens[.management])
        expect(managementScreen.type.rawValue) == "MANAGEMENT"
        expect(managementScreen.title) == "Management Screen"
        expect(managementScreen.subtitle) == "Manage your account"
        expect(managementScreen.paths.count) == 3

        let paths = try XCTUnwrap(managementScreen.paths)

        expect(paths[0].id) == "path1"
        expect(paths[0].title) == "Path 1"
        expect(paths[0].type.rawValue) == "MISSING_PURCHASE"
        expect(paths[0].detail).to(beNil())

        expect(paths[1].id) == "path2"
        expect(paths[1].title) == "Path 2"
        expect(paths[1].type.rawValue) == "CANCEL"
        if case let .promotionalOffer(promotionalOffer) = paths[1].detail {
            expect(promotionalOffer.iosOfferId) == "offer_id"
            expect(promotionalOffer.eligible).to(beTrue())
        } else {
            fail("Expected promotionalOffer detail")
        }

        expect(paths[2].id) == "path3"
        expect(paths[2].title) == "Path 3"
        expect(paths[2].type.rawValue) == "CHANGE_PLANS"
        if case let .feedbackSurvey(feedbackSurvey) = paths[2].detail {
            expect(feedbackSurvey.title) == "survey title"
            expect(feedbackSurvey.options.count) == 1
            expect(feedbackSurvey.options.first?.id) == "id_1"
            expect(feedbackSurvey.options.first?.title) == "option 1"
        } else {
            fail("Expected feedbackSurvey detail")
        }

        expect(configData.lastPublishedAppVersion) == "1.2.3"
    }

}

#endif
