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

// swiftlint:disable missing_docs
// swiftlint:disable nesting
public struct CustomerCenterConfigData {

    public let screens: [Screen.ScreenType: Screen]
    public let appearance: Appearance
    public let localization: Localization

    public init(screens: [Screen.ScreenType: Screen], appearance: Appearance, localization: Localization) {
        self.screens = screens
        self.appearance = appearance
        self.localization = localization
    }

    public struct Localization {

        let locale: String
        let localizedStrings: [String: String]

        public init(locale: String, localizedStrings: [String: String]) {
            self.locale = locale
            self.localizedStrings = localizedStrings
        }

    }

    public struct HelpPath {

        public let id: String
        public let title: String
        public let type: PathType
        public let detail: PathDetail?

        public init(id: String,
                    title: String,
                    type: PathType,
                    detail: PathDetail?) {
            self.id = id
            self.title = title
            self.type = type
            self.detail = detail
        }

        public enum PathDetail {

            case promotionalOffer(PromotionalOffer)
            case feedbackSurvey(FeedbackSurvey)

        }

        public enum PathType: String {

            case missingPurchase = "MISSING_PURCHASE"
            case refundRequest = "REFUND_REQUEST"
            case changePlans = "CHANGE_PLANS"
            case cancel = "CANCEL"
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
                default:
                    self = .unknown
                }
            }

        }

        public struct PromotionalOffer {

            public let iosOfferId: String
            public let eligible: Bool

            public init(iosOfferId: String, eligible: Bool) {
                self.iosOfferId = iosOfferId
                self.eligible = eligible
            }

        }

        public struct FeedbackSurvey {

            public let title: String
            public let options: [Option]

            public init(title: String, options: [Option]) {
                self.title = title
                self.options = options
            }

            public struct Option {

                public let id: String
                public let title: String

                public init(id: String, title: String) {
                    self.id = id
                    self.title = title
                }

            }

        }

    }

    public struct Appearance {

        let mode: AppearanceMode
        let light: AppearanceCustomColors
        let dark: AppearanceCustomColors

        public init(mode: AppearanceMode, light: AppearanceCustomColors, dark: AppearanceCustomColors) {
            self.mode = mode
            self.light = light
            self.dark = dark
        }

        public struct AppearanceCustomColors {

            let accentColor: String
            let backgroundColor: String
            let textColor: String

            public init(accentColor: String, backgroundColor: String, textColor: String) {
                self.accentColor = accentColor
                self.backgroundColor = backgroundColor
                self.textColor = textColor
            }

        }

        public enum AppearanceMode: String {

            case custom = "CUSTOM"
            case system = "SYSTEM"

            init(from rawValue: String) {
                switch rawValue {
                case "CUSTOM":
                    self = .custom
                case "SYSTEM":
                    self = .system
                default:
                    self = .system
                }
            }

        }

    }

    public struct Screen {

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

        public enum ScreenType: String {
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

}

extension CustomerCenterConfigData {

    init(from response: CustomerCenterConfigResponse) {
        let localization = Localization(from: response.customerCenter.localization)
        self.localization = localization
        self.appearance = Appearance(from: response.customerCenter.appearance)
        self.screens = Dictionary(uniqueKeysWithValues: response.customerCenter.screens.map {
            let type = CustomerCenterConfigData.Screen.ScreenType(from: $0.key)
            return (type, Screen(from: $0.value, localization: localization))
        })
    }

}

extension CustomerCenterConfigData.Screen {

    init(from response: CustomerCenterConfigResponse.Screen,
         localization: CustomerCenterConfigData.Localization) {
        self.type = ScreenType(from: response.type.rawValue)
        self.title = response.title
        self.subtitle = response.subtitle
        self.paths = response.paths.map { CustomerCenterConfigData.HelpPath(from: $0) }
    }

}

extension CustomerCenterConfigData.Appearance {

    init(from response: CustomerCenterConfigResponse.Appearance) {
        self.mode = CustomerCenterConfigData.Appearance.AppearanceMode(from: response.mode)
        self.light = CustomerCenterConfigData.Appearance.AppearanceCustomColors(from: response.light)
        self.dark = CustomerCenterConfigData.Appearance.AppearanceCustomColors(from: response.dark)
    }

}

extension CustomerCenterConfigData.Appearance.AppearanceCustomColors {

    init(from response: CustomerCenterConfigResponse.Appearance.AppearanceCustomColors) {
        // swiftlint:disable:next todo
        // TODO: convert colors to PaywallColor (RCColor)
        self.accentColor = response.accentColor
        self.backgroundColor = response.backgroundColor
        self.textColor = response.textColor
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

    init(from response: CustomerCenterConfigResponse.HelpPath) {
        self.id = response.id
        self.title = response.title
        self.type = CustomerCenterConfigData.HelpPath.PathType(from: response.type.rawValue)
        if let promotionalOfferResponse = response.promotionalOffer {
            self.detail = .promotionalOffer(PromotionalOffer(from: promotionalOfferResponse))
        } else if let feedbackSurveyResponse = response.feedbackSurvey {
            self.detail = .feedbackSurvey(FeedbackSurvey(from: feedbackSurveyResponse))
        } else {
            self.detail = nil
        }
    }

}

extension CustomerCenterConfigData.HelpPath.PromotionalOffer {

    init(from response: CustomerCenterConfigResponse.HelpPath.PromotionalOffer) {
        self.iosOfferId = response.iosOfferId
        self.eligible = response.eligible
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
    }

}
