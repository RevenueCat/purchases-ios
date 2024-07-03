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

    struct CustomerCenter {

        let locale: String
        let paths: [HelpPath]
        let supportEmail: String
        let appearance: Appearance
        let screens: [Screen]
        let localization: Localization

    }

    struct Localization {

        let supported: [String]
        let `default`: String
        let localizedStrings: [String: String]

    }

    struct HelpPath {

        let id: String
        let title: String
        let type: PathType
        let promotionalOffer: PromotionalOffer?
        let feedbackSurvey: FeedbackSurvey?

        enum PathType: String {

            case missingPurchase = "MISSING_PURCHASE"
            case refundRequest = "REFUND_REQUEST"
            case changePlans = "CHANGE_PLANS"
            case cancel = "CANCEL"
            case unknown

        }

        struct PromotionalOffer {

            let iosOfferId: String

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

        let mode: String
        let light: AppearanceMode
        let dark: AppearanceMode

        struct AppearanceMode {

            let accentColor: String
            let backgroundColor: String
            let textColor: String

        }

    }

    struct Screen {
        let title: String
        let type: ScreenType
        let subtitle: String?

        enum ScreenType: String {

            case management = "MANAGEMENT"
            case noActive = "NO_ACTIVE"
            case unknown

        }
    }

    struct Support {
        
        let email: String
    
    }

}

extension CustomerCenterConfigResponse: Codable, Equatable {}
extension CustomerCenterConfigResponse.CustomerCenter: Codable, Equatable {}
extension CustomerCenterConfigResponse.Localization: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PathType: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PromotionalOffer: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.FeedbackSurvey: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.FeedbackSurvey.Option: Codable, Equatable {}
extension CustomerCenterConfigResponse.Appearance: Codable, Equatable {}
extension CustomerCenterConfigResponse.Appearance.AppearanceMode: Codable, Equatable {}
extension CustomerCenterConfigResponse.Screen: Codable, Equatable {}
extension CustomerCenterConfigResponse.Screen.ScreenType: Codable, Equatable {}

extension CustomerCenterConfigResponse: HTTPResponseBody {}
