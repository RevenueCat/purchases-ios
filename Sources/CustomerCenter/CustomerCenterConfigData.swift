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
public typealias RCColor = PaywallColor

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

        public enum CommonLocalizedString: String {

            case noThanks = "no_thanks"
            case noSubscriptionsFound = "no_subscriptions_found"
            case tryCheckRestore = "try_check_restore"
            case restorePurchases = "restore_purchases"
            case cancel = "cancel"

            var defaultValue: String {
                switch self {
                case .noThanks:
                    return "No, thanks"
                case .noSubscriptionsFound:
                    return "No Subscriptions found"
                case .tryCheckRestore:
                    return "We can try checking your Apple account for any previous purchases"
                case .restorePurchases:
                    return "Restore purchases"
                case .cancel:
                    return "Cancel"
                }
            }

        }

        public func commonLocalizedString(for key: CommonLocalizedString) -> String {
            return self.localizedStrings[key.rawValue] ?? key.defaultValue
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
            public let title: String
            public let subtitle: String

            public init(iosOfferId: String, eligible: Bool, title: String, subtitle: String) {
                self.iosOfferId = iosOfferId
                self.eligible = eligible
                self.title = title
                self.subtitle = subtitle
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
                public let promotionalOffer: PromotionalOffer?

                public init(id: String, title: String, promotionalOffer: PromotionalOffer?) {
                    self.id = id
                    self.title = title
                    self.promotionalOffer = promotionalOffer
                }

            }

        }

    }

    public struct Appearance {

        public let mode: AppearanceMode

        public init(mode: AppearanceMode) {
            self.mode = mode
        }

        public enum AppearanceMode {

            case system
            case custom(accentColor: RCColor, backgroundColor: RCColor, textColor: RCColor)

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

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CustomerCenterConfigData.Appearance {

    init(from response: CustomerCenterConfigResponse.Appearance) {
        self.mode = CustomerCenterConfigData.Appearance.AppearanceMode(from: response)
    }

}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension CustomerCenterConfigData.Appearance.AppearanceMode {

    init(from response: CustomerCenterConfigResponse.Appearance) {
        switch response.mode {
        case .system:
            self = .system
        case .custom:
            do {
                let accent = RCColor(light: try RCColor(stringRepresentation: response.light.accentColor),
                                     dark: try RCColor(stringRepresentation: response.dark.accentColor))
                let background = RCColor(light: try RCColor(stringRepresentation: response.light.backgroundColor),
                                         dark: try RCColor(stringRepresentation: response.dark.backgroundColor))
                let text = RCColor(light: try RCColor(stringRepresentation: response.light.textColor),
                                   dark: try RCColor(stringRepresentation: response.dark.textColor))
                self = .custom(accentColor: accent,
                               backgroundColor: background,
                               textColor: text)
            } catch {
                Logger.error("Failed to parse appearance colors")
                self = .system
            }
        }
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
        self.title = response.title
        self.subtitle = response.subtitle
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
