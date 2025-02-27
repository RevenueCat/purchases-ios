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

    public struct Localization: Equatable {

        let locale: String
        let localizedStrings: [String: String]

        public init(locale: String, localizedStrings: [String: String]) {
            self.locale = locale
            self.localizedStrings = localizedStrings
        }

        public enum CommonLocalizedString: String, Equatable {

            case copy = "copy"
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
            case unknown = "unknown"
            case updateWarningTitle = "update_warning_title"
            case updateWarningDescription = "update_warning_description"
            case updateWarningUpdate = "update_warning_update"
            case updateWarningIgnore = "update_warning_ignore"
            case pleaseContactSupportToManage = "please_contact_support"
            case appleSubscriptionManage = "apple_subscription_manage"
            case googleSubscriptionManage = "google_subscription_manage"
            case amazonSubscriptionManage = "amazon_subscription_manage"
            case webSubscriptionManage = "web_subscription_manage"
            case platformMismatch = "platform_mismatch"
            case goingToCheckPurchases = "going_to_check_purchases"
            case checkPastPurchases = "check_past_purchases"
            case purchasesRecovered = "purchases_recovered"
            case purchasesRecoveredExplanation = "purchases_recovered_explanation"
            case purchasesNotRecovered = "purchases_not_recovered"
            case manageSubscription = "manage_subscription"
            case youHavePromo = "you_have_promo"
            case youHaveLifetime = "you_have_lifetime"
            case free = "free"
            case never = "never"
            case seeAllPurchases = "screen_management_see_all_purchases"
            case purchaseInfoPurchasedOnDate = "purchase_info_purchased_on_date"
            case purchaseInfoExpiredOnDate = "purchase_info_expired_on_date"
            case purchaseInfoRenewsOnDate = "purchase_info_renews_on_date"
            case purchaseInfoExpiresOnDate = "purchase_info_expires_on_date"
            case activeSubscriptions = "screen_purchase_history_active_subscriptions_title"
            case expiredSubscriptions = "screen_purchase_history_expired_subscriptions_title"
            case otherPurchases = "screen_purchase_history_others_title"
            case accountDetails = "screen_purchase_history_account_details_title"
            case dateWhenAppWasPurchased = "screen_purchase_history_original_purchase_date"
            case userId = "screen_purchase_history_user_id"
            case purchaseHistory = "screen_purchase_history_title"
            case sharedThroughFamilyMember = "shared_through_family_member"
            case active = "active"
            case inactive = "inactive"
            case introductoryPrice = "introductory_price"
            case trialPeriod = "trial_period"
            case productName = "product_name"
            case paidPrice = "paid_price"
            case originalDownloadDate = "original_download_date"
            case status = "status"
            case nextRenewalDate = "next_renewal"
            case unsubscribedAt = "unsubscribed_at"
            case billingIssueDetectedAt = "billing_issue_detected_at"
            case gracePeriodExpiresAt = "grace_period_expires_at"
            case periodType = "period_type"
            case refundedAt = "refunded_at"
            case store = "store"
            case productID = "product_id"
            case sandbox = "sandbox"
            case transactionID = "transaction_id"
            case answerYes = "yes"
            case answerNo = "no"
            case storeAppStore = "store_app_store"
            case storeMacAppStore = "store_mac_app_store"
            case storePlayStore = "store_google_play_store"
            case storeStripe = "store_stripe"
            case storePromotional = "store_promotional"
            case storeAmazon = "store_amazon_store"
            case storeRCBilling = "store_web"
            case storeExternal = "store_external"
            case storeUnknownStore = "store_unknown"
            case debugHeaderTitle = "Debug"

            var defaultValue: String {
                switch self {
                case .copy:
                    return "Copy"
                case .noThanks:
                    return "No, thanks"
                case .noSubscriptionsFound:
                    return "No Subscriptions found"
                case .tryCheckRestore:
                    return "We can try checking your Apple account for any previous purchases"
                case .restorePurchases:
                    return "Restore purchases"
                case .goingToCheckPurchases:
                    return "Let’s take a look! We’re going to check your account for missing purchases."
                case .checkPastPurchases:
                    return "Check past purchases"
                case .purchasesRecovered:
                    return "Purchases recovered!"
                case .purchasesRecoveredExplanation:
                    return "We applied the previously purchased items to your account. Sorry for the inconvenience."
                case .purchasesNotRecovered:
                    return "We couldn't find any additional purchases under this account. " +
                    "Contact support for assistance if you think this is an error."
                case .cancel:
                    return "Cancel"
                case .billingCycle:
                    return "Billing cycle"
                case .currentPrice:
                    return "Price"
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
                    return "Refund requested"
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
                case .unknown:
                    return "Unknown"
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
                    return "You have an active subscription from the Apple App Store. " +
                    "You can manage your subscription by using the App Store app on an Apple device."
                case .googleSubscriptionManage:
                    return "You have an active subscription from the Google Play Store"
                case .amazonSubscriptionManage:
                    return "You have an active subscription from the Amazon Appstore. " +
                    "You can manage your subscription in the Amazon Appstore app."
                case .webSubscriptionManage:
                    return "You have an active subscription that was created on the web." +
                    " You can manage your subscription by visiting your account."
                case .manageSubscription:
                    return "Manage your subscription"
                case .youHavePromo:
                    return "You’ve been granted a subscription that doesn’t renew"
                case .youHaveLifetime:
                    return "Your active lifetime subscription"
                case .free:
                    return "Free"
                case .never:
                    return "Never"
                case .seeAllPurchases:
                    return "See All Purchases"
                case .purchaseInfoPurchasedOnDate:
                    return "Purchased on {{ date }}"
                case .purchaseInfoExpiredOnDate:
                    return "Expired on {{ date }}"
                case .purchaseInfoRenewsOnDate:
                    return "Renews on {{ date }}"
                case .purchaseInfoExpiresOnDate:
                    return "Expires on {{ date }}"
                case .activeSubscriptions:
                    return "Active Subscriptions"
                case .expiredSubscriptions:
                    return "Expired Subscriptions"
                case .otherPurchases:
                    return "Other"
                case .accountDetails:
                    return "Account Details"
                case .dateWhenAppWasPurchased:
                    return "Original Download Date"
                case .userId:
                    return "User ID"
                case .purchaseHistory:
                    return "Purchase History"
                case .sharedThroughFamilyMember:
                    return "Shared through family member"
                case .active:
                    return "Active"
                case .inactive:
                    return "Inactive"
                case .introductoryPrice:
                    return "Introductory Price"
                case .trialPeriod:
                    return "Trial Period"
                case .productName:
                    return "Product Name"
                case .paidPrice:
                    return "Paid Price"
                case .originalDownloadDate:
                    return "Original Download Date"
                case .status:
                    return "Status"
                case .nextRenewalDate:
                    return "Next Renewal"
                case .unsubscribedAt:
                    return "Unsubscribed At"
                case .billingIssueDetectedAt:
                    return "Billing Issue Detected At"
                case .gracePeriodExpiresAt:
                    return "Grace Period Expires At"
                case .periodType:
                    return "Period Type"
                case .refundedAt:
                    return "Refunded At"
                case .store:
                    return "Store"
                case .productID:
                    return "Product ID"
                case .sandbox:
                    return "Sandbox"
                case .transactionID:
                    return "Transaction ID"
                case .answerYes:
                    return "Yes"
                case .answerNo:
                    return "No"
                case .storeAppStore:
                    return "Apple App Store"
                case .storeMacAppStore:
                    return "Mac App Store"
                case .storePlayStore:
                    return "Google Play Store"
                case .storeStripe:
                    return "Stripe"
                case .storePromotional:
                    return "Promotional"
                case .storeAmazon:
                    return "Amazon Store"
                case .storeRCBilling:
                    return "Web"
                case .storeExternal:
                    return "External Purchases"
                case .storeUnknownStore:
                    return "Unknown Store"
                case .debugHeaderTitle:
                    return "Debug"
                }
            }
        }

        public subscript(_ key: CommonLocalizedString) -> String {
            localizedStrings[key.rawValue] ?? key.defaultValue
        }
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

        public init(
            email: String,
            shouldWarnCustomerToUpdate: Bool,
            displayPurchaseHistoryLink: Bool
        ) {
            self.email = email
            self.shouldWarnCustomerToUpdate = shouldWarnCustomerToUpdate
            self.displayPurchaseHistoryLink = displayPurchaseHistoryLink
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
    }

}

extension CustomerCenterConfigData.HelpPath.PathType: Sendable, Codable {}
