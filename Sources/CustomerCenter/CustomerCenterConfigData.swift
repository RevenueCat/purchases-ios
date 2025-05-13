//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// CustomerCenterConfigData.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation

// swiftlint:disable missing_docs nesting file_length type_body_length
public typealias RCColor = PaywallColor

public struct CustomerCenterConfigData: Equatable {

    public let screens: [Screen.ScreenType: Screen]
    public let appearance: Appearance
    public let localization: Localization
    public let support: Support
    public let lastPublishedAppVersion: String?
    public let productId: UInt?

    public init(screens: [Screen.ScreenType: Screen],
                appearance: Appearance,
                localization: Localization,
                support: Support,
                lastPublishedAppVersion: String?,
                productId: UInt?) {
        self.screens = screens
        self.appearance = appearance
        self.localization = localization
        self.support = support
        self.lastPublishedAppVersion = lastPublishedAppVersion
        self.productId = productId
    }

    public struct HelpPath: Equatable {

        public let id: String
        public let title: String
        public let url: URL?
        public let openMethod: OpenMethod?
        public let type: PathType
        public let detail: PathDetail?
        public let refundWindowDuration: RefundWindowDuration?

        public init(id: String,
                    title: String,
                    url: URL? = nil,
                    openMethod: OpenMethod? = nil,
                    type: PathType,
                    detail: PathDetail?,
                    refundWindowDuration: RefundWindowDuration? = nil) {
            self.id = id
            self.title = title
            self.url = url
            self.openMethod = openMethod
            self.type = type
            self.detail = detail
            self.refundWindowDuration = refundWindowDuration
        }

        public enum PathDetail: Equatable {

            case promotionalOffer(PromotionalOffer)
            case feedbackSurvey(FeedbackSurvey)

        }

        public enum RefundWindowDuration: Equatable {
            case forever
            case duration(ISODuration)
        }

        public enum PathType: String, Equatable {

            case missingPurchase = "MISSING_PURCHASE"
            case refundRequest = "REFUND_REQUEST"
            case changePlans = "CHANGE_PLANS"
            case cancel = "CANCEL"
            case customUrl = "CUSTOM_URL"
            case unknown

            init(from rawValue: String) {
                switch rawValue {
                case "MISSING_PURCHASE":
                    self = .missingPurchase
                case "REFUND_REQUEST":
                    self = .refundRequest
                case "CHANGE_PLANS":
                    self = .changePlans
                case "CANCEL":
                    self = .cancel
                case "CUSTOM_URL":
                    self = .customUrl
                default:
                    self = .unknown
                }
            }

        }

        public enum OpenMethod: String, Equatable {

            case inApp = "IN_APP"
            case external = "EXTERNAL"

            init?(from rawValue: String?) {
                switch rawValue {
                case "IN_APP":
                    self = .inApp
                case "EXTERNAL":
                    self = .external
                default:
                    return nil
                }
            }

        }

        public struct PromotionalOffer: Equatable {

            public let iosOfferId: String
            public let eligible: Bool
            public let title: String
            public let subtitle: String
            public let productMapping: [String: String]

            public init(iosOfferId: String,
                        eligible: Bool,
                        title: String,
                        subtitle: String,
                        productMapping: [String: String]) {
                self.iosOfferId = iosOfferId
                self.eligible = eligible
                self.title = title
                self.subtitle = subtitle
                self.productMapping = productMapping
            }

        }

        public struct FeedbackSurvey: Equatable {

            public let title: String
            public let options: [Option]

            public init(title: String, options: [Option]) {
                self.title = title
                self.options = options
            }

            public struct Option: Equatable {

                public let id: String
                public let title: String
                public let promotionalOffer: PromotionalOffer?

                public init(id: String, title: String, promotionalOffer: PromotionalOffer?) {
                    self.id = id
                    self.title = title
                    self.promotionalOffer = promotionalOffer
                }

            }

        }

    }

    public struct Appearance: Equatable {

        public let accentColor: ColorInformation
        public let textColor: ColorInformation
        public let backgroundColor: ColorInformation
        public let buttonTextColor: ColorInformation
        public let buttonBackgroundColor: ColorInformation

        public init(accentColor: ColorInformation,
                    textColor: ColorInformation,
                    backgroundColor: ColorInformation,
                    buttonTextColor: ColorInformation,
                    buttonBackgroundColor: ColorInformation) {
            self.accentColor = accentColor
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            self.buttonTextColor = buttonTextColor
            self.buttonBackgroundColor = buttonBackgroundColor
        }

        public struct ColorInformation: Equatable {

            public var light: RCColor?
            public var dark: RCColor?

            public init() {
                self.light = nil
                self.dark = nil
            }

            public init(
                light: String?,
                dark: String?
            ) {
                if let light = light {
                    do {
                        self.light = try RCColor(stringRepresentation: light)
                    } catch {
                        Logger.error("Failed to parse light color \(light)")
                    }
                }
                if let dark = dark {
                    do {
                        self.dark = try RCColor(stringRepresentation: dark)
                    } catch {
                        Logger.error("Failed to parse dark color \(dark)")
                    }
                }
            }
        }

    }

    public struct Screen: Equatable {

        public let type: ScreenType
        public let title: String
        public let subtitle: String?
        public let paths: [HelpPath]

        public init(type: ScreenType, title: String, subtitle: String?, paths: [HelpPath]) {
            self.type = type
            self.title = title
            self.subtitle = subtitle
            self.paths = paths
        }

        public enum ScreenType: String, Equatable {
            case management = "MANAGEMENT"
            case noActive = "NO_ACTIVE"
            case unknown

            init(from rawValue: String) {
                switch rawValue {
                case "MANAGEMENT":
                    self = .management
                case "NO_ACTIVE":
                    self = .noActive
                default:
                    self = .unknown
                }
            }
        }

    }

    public struct Support: Equatable {

        public let email: String
        public let shouldWarnCustomerToUpdate: Bool
        public let displayPurchaseHistoryLink: Bool
        public let shouldWarnCustomersAboutMultipleSubscriptions: Bool

        public init(
            email: String,
            shouldWarnCustomerToUpdate: Bool,
            displayPurchaseHistoryLink: Bool,
            shouldWarnCustomersAboutMultipleSubscriptions: Bool
        ) {
            self.email = email
            self.shouldWarnCustomerToUpdate = shouldWarnCustomerToUpdate
            self.displayPurchaseHistoryLink = displayPurchaseHistoryLink
            self.shouldWarnCustomersAboutMultipleSubscriptions = shouldWarnCustomersAboutMultipleSubscriptions
        }

    }

}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CustomerCenterConfigData {

    init(from response: CustomerCenterConfigResponse) {
        let localization = Localization(from: response.customerCenter.localization)
        self.localization = localization
        self.appearance = Appearance(from: response.customerCenter.appearance)
        self.screens = Dictionary(uniqueKeysWithValues: response.customerCenter.screens.map {
            let type = CustomerCenterConfigData.Screen.ScreenType(from: $0.key)
            return (type, Screen(from: $0.value, localization: localization))
        })
        self.support = Support(from: response.customerCenter.support)
        self.lastPublishedAppVersion = response.lastPublishedAppVersion
        self.productId = response.itunesTrackId
    }

}

extension CustomerCenterConfigData.Screen {

    init(from response: CustomerCenterConfigResponse.Screen,
         localization: CustomerCenterConfigData.Localization) {
        self.type = ScreenType(from: response.type.rawValue)
        self.title = response.title
        self.subtitle = response.subtitle
        self.paths = response.paths.compactMap { CustomerCenterConfigData.HelpPath(from: $0) }
    }

}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CustomerCenterConfigData.Appearance {

    init(from response: CustomerCenterConfigResponse.Appearance) {
        self.accentColor = .init(light: response.light.accentColor,
                                 dark: response.dark.accentColor)
        self.textColor = .init(light: response.light.textColor,
                               dark: response.dark.textColor)
        self.backgroundColor = .init(light: response.light.backgroundColor,
                                     dark: response.dark.backgroundColor)
        self.buttonTextColor = .init(light: response.light.buttonTextColor,
                                     dark: response.dark.buttonTextColor)
        self.buttonBackgroundColor = .init(light: response.light.buttonBackgroundColor,
                                           dark: response.dark.buttonBackgroundColor)
    }

}

extension CustomerCenterConfigData.Localization {

    init(from response: CustomerCenterConfigResponse.Localization) {
        // swiftlint:disable:next todo
        // TODO: convert to Locale
        self.locale = response.locale
        self.localizedStrings = response.localizedStrings
    }

}

extension CustomerCenterConfigData.HelpPath {

    init?(from response: CustomerCenterConfigResponse.HelpPath) {
        self.id = response.id
        self.title = response.title
        self.type = CustomerCenterConfigData.HelpPath.PathType(from: response.type.rawValue)
        if self.type == .customUrl {
            if let responseUrl = response.url,
               let url = URL(string: responseUrl),
               let openMethod = CustomerCenterConfigData.HelpPath.OpenMethod(from: response.openMethod?.rawValue) {
                self.url = url
                self.openMethod = openMethod
            } else {
                return nil
            }
        } else {
            self.url = nil
            self.openMethod = nil
        }
        if let promotionalOfferResponse = response.promotionalOffer {
            self.detail = .promotionalOffer(PromotionalOffer(from: promotionalOfferResponse))
        } else if let feedbackSurveyResponse = response.feedbackSurvey {
            self.detail = .feedbackSurvey(FeedbackSurvey(from: feedbackSurveyResponse))
        } else {
            self.detail = nil
        }

        if let window = response.refundWindow {
            self.refundWindowDuration = window == "forever"
                ? RefundWindowDuration.forever
                : ISODurationFormatter.parse(from: window).map { .duration($0) }
        } else {
            self.refundWindowDuration = nil
        }
    }
}

extension CustomerCenterConfigData.HelpPath.PromotionalOffer {

    init(from response: CustomerCenterConfigResponse.HelpPath.PromotionalOffer) {
        self.iosOfferId = response.iosOfferId
        self.eligible = response.eligible
        self.title = response.title
        self.subtitle = response.subtitle
        self.productMapping = response.productMapping
    }

}

extension CustomerCenterConfigData.HelpPath.FeedbackSurvey {

    init(from response: CustomerCenterConfigResponse.HelpPath.FeedbackSurvey) {
        self.title = response.title
        self.options = response.options.map { Option(from: $0) }
    }

}

extension CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option {

    init(from response: CustomerCenterConfigResponse.HelpPath.FeedbackSurvey.Option) {
        self.id = response.id
        self.title = response.title
        if let promotionalOffer = response.promotionalOffer {
            self.promotionalOffer = CustomerCenterConfigData.HelpPath.PromotionalOffer(from: promotionalOffer)
        } else {
            self.promotionalOffer = nil
        }

    }

}

extension CustomerCenterConfigData.Support {

    init(from response: CustomerCenterConfigResponse.Support) {
        self.email = response.email
        self.shouldWarnCustomerToUpdate = response.shouldWarnCustomerToUpdate ?? true
        self.displayPurchaseHistoryLink = response.displayPurchaseHistoryLink ?? false
        self.shouldWarnCustomersAboutMultipleSubscriptions = response.shouldWarnCustomersAboutMultipleSubscriptions
            ?? false
    }

}

extension CustomerCenterConfigData.HelpPath.PathType: Sendable, Codable {}
