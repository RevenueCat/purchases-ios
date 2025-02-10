//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigResponse.swift
//
//
//  Created by Cesar de la Vega on 31/5/24.
//

import Foundation

// swiftlint:disable nesting

struct CustomerCenterConfigResponse {

    let customerCenter: CustomerCenter
    let lastPublishedAppVersion: String?
    let itunesTrackId: UInt?

    struct CustomerCenter {

        let appearance: Appearance
        let screens: [String: Screen]
        let localization: Localization
        let support: Support

    }

    struct Localization {

        let locale: String
        let localizedStrings: [String: String]

    }

    struct HelpPath {

        let id: String
        let title: String
        let type: PathType
        let url: String?
        let openMethod: OpenMethod?
        let promotionalOffer: PromotionalOffer?
        let feedbackSurvey: FeedbackSurvey?
        let refundWindow: String?

        enum PathType: String {

            case missingPurchase = "MISSING_PURCHASE"
            case refundRequest = "REFUND_REQUEST"
            case changePlans = "CHANGE_PLANS"
            case cancel = "CANCEL"
            case customUrl = "CUSTOM_URL"
            case unknown

        }

        enum OpenMethod: String {

            case inApp = "IN_APP"
            case external = "EXTERNAL"
            case unknown

        }

        struct PromotionalOffer {

            let iosOfferId: String
            let eligible: Bool
            let title: String
            let subtitle: String
            let productMapping: [String: String]

        }

        struct FeedbackSurvey {

            let title: String
            let options: [Option]

            struct Option {

                let id: String
                let title: String
                let promotionalOffer: PromotionalOffer?

            }

        }

    }

    struct Appearance {

        let light: AppearanceCustomColors
        let dark: AppearanceCustomColors

        struct AppearanceCustomColors {

            let accentColor: String?
            let textColor: String?
            let backgroundColor: String?
            let buttonTextColor: String?
            let buttonBackgroundColor: String?

        }

    }

    struct Screen {

        let title: String
        let type: ScreenType
        let subtitle: String?
        let paths: [HelpPath]

        enum ScreenType: String {

            case management = "MANAGEMENT"
            case noActive = "NO_ACTIVE"
            case unknown

        }

    }

    struct Support {

        let email: String
        let shouldWarnCustomerToUpdate: Bool?
        let displayPurchaseHistoryLink: Bool?
    }

}

extension CustomerCenterConfigResponse: Codable, Equatable {}
extension CustomerCenterConfigResponse.CustomerCenter: Codable, Equatable {}
extension CustomerCenterConfigResponse.Localization: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PathType: Equatable {}
extension CustomerCenterConfigResponse.HelpPath.OpenMethod: Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PromotionalOffer: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.FeedbackSurvey: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.FeedbackSurvey.Option: Codable, Equatable {}
extension CustomerCenterConfigResponse.Appearance: Codable, Equatable {}
extension CustomerCenterConfigResponse.Appearance.AppearanceCustomColors: Codable, Equatable {}
extension CustomerCenterConfigResponse.Screen: Codable, Equatable {}
extension CustomerCenterConfigResponse.Screen.ScreenType: Equatable {}
extension CustomerCenterConfigResponse.Support: Codable, Equatable {}

protocol CodableEnumWithUnknownCase: Codable {

    static var unknownCase: Self { get }

}

extension CodableEnumWithUnknownCase where Self: RawRepresentable, Self.RawValue == String {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = Self(rawValue: value) ?? Self.unknownCase
    }

}

extension CustomerCenterConfigResponse.Screen.ScreenType: CodableEnumWithUnknownCase {

    static var unknownCase: Self { .unknown }

}

extension CustomerCenterConfigResponse.HelpPath.PathType: CodableEnumWithUnknownCase {

    static var unknownCase: Self { .unknown }

}

extension CustomerCenterConfigResponse.HelpPath.OpenMethod: CodableEnumWithUnknownCase {

    static var unknownCase: Self { .unknown }

}

extension CustomerCenterConfigResponse: HTTPResponseBody {}
