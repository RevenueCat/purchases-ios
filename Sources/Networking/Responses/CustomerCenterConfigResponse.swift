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
        let changePlans: [ChangePlan]

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
        let actionIdentifier: String?

        enum PathType: String {

            case missingPurchase = "MISSING_PURCHASE"
            case refundRequest = "REFUND_REQUEST"
            case changePlans = "CHANGE_PLANS"
            case cancel = "CANCEL"
            case customUrl = "CUSTOM_URL"
            case customAction = "CUSTOM_ACTION"
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
            let crossProductPromotions: [String: CrossProductPromotion]?

            struct CrossProductPromotion {
                let storeOfferIdentifier: String
                let targetProductId: String
            }

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
        let offering: ScreenOffering?

        enum ScreenType: String {

            case management = "MANAGEMENT"
            case noActive = "NO_ACTIVE"
            case unknown

        }

    }

    struct ScreenOffering {
        let type: String
        let offeringId: String?
        let buttonText: String?
    }

    struct Support {

        let email: String
        let shouldWarnCustomerToUpdate: Bool?
        let displayPurchaseHistoryLink: Bool?
        let displayUserDetailsSection: Bool?
        let displayVirtualCurrencies: Bool?
        let shouldWarnCustomersAboutMultipleSubscriptions: Bool?
        let supportTickets: SupportTickets?

        struct SupportTickets {
            let allowCreation: Bool
            let customerType: String
            let customerDetails: CustomerDetails?

            struct CustomerDetails {
                let activeEntitlements: Bool?
                let appUserId: Bool?
                let attConsent: Bool?
                let country: Bool?
                let deviceVersion: Bool?
                let email: Bool?
                let facebookAnonId: Bool?
                let idfa: Bool?
                let idfv: Bool?
                let ipAddress: Bool?
                let lastOpened: Bool?
                let lastSeenAppVersion: Bool?
                let totalSpent: Bool?
                let userSince: Bool?

                enum CodingKeys: String, CodingKey {
                    case activeEntitlements = "active_entitlements"
                    case appUserId = "app_user_id"
                    case attConsent = "att_consent"
                    case country
                    case deviceVersion = "device_version"
                    case email
                    case facebookAnonId = "facebook_anon_id"
                    case idfa
                    case idfv
                    case ipAddress = "ip"
                    case lastOpened = "last_opened"
                    case lastSeenAppVersion = "last_seen_app_version"
                    case totalSpent = "total_spent"
                    case userSince = "user_since"
                }
            }
        }
    }

    struct ChangePlan {
        let groupId: String
        let groupName: String
        let products: [ChangePlanProduct]
    }

    struct ChangePlanProduct {
        let productId: String
        let selected: Bool
    }

}

extension CustomerCenterConfigResponse: Codable, Equatable {}
extension CustomerCenterConfigResponse.CustomerCenter: Codable, Equatable {}
extension CustomerCenterConfigResponse.Localization: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PathType: Equatable {}
extension CustomerCenterConfigResponse.HelpPath.OpenMethod: Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PromotionalOffer: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.PromotionalOffer.CrossProductPromotion: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.FeedbackSurvey: Codable, Equatable {}
extension CustomerCenterConfigResponse.HelpPath.FeedbackSurvey.Option: Codable, Equatable {}
extension CustomerCenterConfigResponse.Appearance: Codable, Equatable {}
extension CustomerCenterConfigResponse.Appearance.AppearanceCustomColors: Codable, Equatable {}
extension CustomerCenterConfigResponse.Screen: Codable, Equatable {}
extension CustomerCenterConfigResponse.ScreenOffering: Codable, Equatable {}
extension CustomerCenterConfigResponse.Screen.ScreenType: Equatable {}
extension CustomerCenterConfigResponse.Support: Codable, Equatable {}
extension CustomerCenterConfigResponse.Support.SupportTickets: Codable, Equatable {}
extension CustomerCenterConfigResponse.Support.SupportTickets.CustomerDetails: Codable, Equatable {}
extension CustomerCenterConfigResponse.ChangePlan: Codable, Equatable {}
extension CustomerCenterConfigResponse.ChangePlanProduct: Codable, Equatable {}

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
