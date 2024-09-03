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

#if CUSTOMER_CENTER_ENABLED

import Foundation

// swiftlint:disable missing_docs nesting file_length type_body_length
public typealias RCColor = PaywallColor

public struct CustomerCenterConfigData {

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
            case billingCycle = "billing_cycle"
            case currentPrice = "current_price"
            case expired = "expired"
            case expires = "expires"
            case nextBillingDate = "next_billing_date"
            case refundCanceled = "refund_canceled"
            case refundErrorGeneric = "refund_error_generic"
            case refundGranted = "refund_granted"
            case refundStatus = "refund_status"
            case subEarliestExpiration = "sub_earliest_expiration"
            case subEarliestRenewal = "sub_earliest_renewal"
            case subExpired = "sub_expired"
            case contactSupport = "contact_support"
            case defaultBody = "default_body"
            case defaultSubject = "default_subject"
            case dismiss = "dismiss"
            case updateWarningTitle = "update_warning_title"
            case updateWarningDescription = "update_warning_description"
            case updateWarningUpdate = "update_warning_update"
            case updateWarningIgnore = "update_warning_ignore"
            case pleaseContactSupportToManage = "please_contact_support"
            case appleSubscriptionManage = "apple_subscription_manage"
            case googleSubscriptionManage = "google_subscription_manage"
            case amazonSubscriptionManage = "amazon_subscription_manage"
            case platformMismatch = "platform_mismatch"

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
                case .billingCycle:
                    return "Billing cycle"
                case .currentPrice:
                    return "Current price"
                case .expired:
                    return "Expired"
                case .expires:
                    return "Expires"
                case .nextBillingDate:
                    return "Next billing date"
                case .refundCanceled:
                    return "Refund canceled"
                case .refundErrorGeneric:
                    return "An error occurred while processing the refund request. Please try again."
                case .refundGranted:
                    return "Refund granted successfully!"
                case .refundStatus:
                    return "Refund status"
                case .subEarliestExpiration:
                    return "This is your subscription with the earliest expiration date."
                case .subEarliestRenewal:
                    return "This is your subscription with the earliest billing date."
                case .subExpired:
                    return "This subscription has expired."
                case .contactSupport:
                    return "Contact support"
                case .defaultBody:
                    return "Please describe your issue or question."
                case .defaultSubject:
                    return "Support Request"
                case .dismiss:
                    return "Dismiss"
                case .updateWarningTitle:
                    return "Update available"
                case .updateWarningDescription:
                    return "Downloading the latest version of the app may help solve the problem."
                case .updateWarningUpdate:
                    return "Update"
                case .updateWarningIgnore:
                    return "Continue"
                case .platformMismatch:
                    return "Platform mismatch"
                case .pleaseContactSupportToManage:
                    return "Please contact support to manage your subscription."
                case .appleSubscriptionManage:
                    return "You can manage your subscription by using the App Store app on an Apple device."
                case .googleSubscriptionManage:
                    return "You can manage your subscription by using the Play Store app on an Android device"
                case .amazonSubscriptionManage:
                    return "You can manage your subscription in the Amazon Appstore app on an Amazon device."
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

        public struct ColorInformation {

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

    public struct Support {

        public let email: String

        public init(email: String) {
            self.email = email
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
        self.paths = response.paths.map { CustomerCenterConfigData.HelpPath(from: $0) }
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

extension CustomerCenterConfigData.Support {

    init(from response: CustomerCenterConfigResponse.Support) {
        self.email = response.email
    }

}

#endif
