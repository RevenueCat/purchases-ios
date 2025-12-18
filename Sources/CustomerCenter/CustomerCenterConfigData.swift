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
@_spi(Internal) public typealias RCColor = PaywallColor

@_spi(Internal) public struct CustomerCenterConfigData: Equatable {

    @_spi(Internal) public let screens: [Screen.ScreenType: Screen]
    @_spi(Internal) public let appearance: Appearance
    @_spi(Internal) public let localization: Localization
    @_spi(Internal) public let support: Support
    @_spi(Internal) public let changePlans: [ChangePlan]
    @_spi(Internal) public let lastPublishedAppVersion: String?
    @_spi(Internal) public let productId: UInt?

    @_spi(Internal) public init(
        screens: [Screen.ScreenType: Screen],
        appearance: Appearance,
        localization: Localization,
        support: Support,
        changePlans: [ChangePlan],
        lastPublishedAppVersion: String?,
        productId: UInt?
    ) {
        self.screens = screens
        self.appearance = appearance
        self.localization = localization
        self.support = support
        self.changePlans = changePlans
        self.lastPublishedAppVersion = lastPublishedAppVersion
        self.productId = productId
    }

    @_spi(Internal) public struct Localization: Equatable {

        let locale: String
        let localizedStrings: [String: String]

        @_spi(Internal) public init(locale: String, localizedStrings: [String: String]) {
            self.locale = locale
            self.localizedStrings = localizedStrings
        }

        @_spi(Internal) public enum CommonLocalizedString: String, Equatable {

            case buySubscrition = "buy_subscription"
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
            case done = "done"
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
            case purchasesRestoring = "purchases_restoring"
            case purchasesRecoveredExplanation = "purchases_recovered_explanation"
            case purchasesNotFound = "purchases_not_found"
            case purchasesNotRecoveredExplanation = "purchases_not_recovered"
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
            case historyLatestPurchaseDate = "history_latest_purchase_date"
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
            case storeAppStore = "app_store"
            case storeMacAppStore = "mac_app_store"
            case storePlayStore = "google_play_store"
            case testStore = "test_store"
            case storeStripe = "stripe"
            case storePromotional = "promotional"
            case storeAmazon = "amazon_store"
            case cardStorePromotional = "card_store_promotional"
            case storeExternal = "external_store"
            case storeUnknownStore = "unknown_store"
            case storePaddle = "store_paddle"
            case storeWeb = "store_web"
            case typeSubscription = "type_subscription"
            case typeOneTimePurchase = "type_one_time_purchase"
            case debugHeaderTitle = "Debug"
            case seeAllVirtualCurrencies = "see_all_virtual_currencies"
            case virtualCurrencyBalancesScreenHeader = "virtual_currency_balances_screen_header"
            case noVirtualCurrencyBalancesFound = "no_virtual_currency_balances_found"
            case youMayHaveDuplicatedSubscriptionsTitle = "you_may_have_duplicated_subscriptions_title"
            case youMayHaveDuplicatedSubscriptionsSubtitle = "you_may_have_duplicated_subscriptions_subtitle"
            case pricePaid = "price_paid"
            case expiresOnDateWithoutChanges = "expires_on_date_without_changes"
            case renewsOnDateForPrice = "renews_on_date_for_price"
            case renewsOnDate = "renews_on_date"
            case priceAfterwards = "price_afterwards"
            case freeTrialUntilDate = "free_trial_until_date"
            case priceExpiresOnDateWithoutChanges = "price_expires_on_date_without_changes"
            case badgeLifetime = "badge_lifetime"
            case badgeCancelled = "badge_cancelled"
            case badgeTrialCancelled = "badge_free_trial_cancelled"
            case badgeFreeTrial = "badge_free_trial"
            case refundSuccess = "refund_success"
            case actionsSectionTitle = "actions_section_title"
            case subscriptionsSectionTitle = "subscriptions_section_title"
            case purchasesSectionTitle = "purchases_section_title"
            case supportTicketCreate = "support_ticket_create"
            case email = "email"
            case enterEmail = "enter_email"
            case description = "description"
            case sent = "sent"
            case supportTicketFailed = "support_ticket_failed"
            case submitTicket = "submit_ticket"
            case characterCount = "character_count"

            @_spi(Internal) public var defaultValue: String {
                switch self {
                case .buySubscrition:
                    return "Subscribe"
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
                    return "Purchases restored"
                case .purchasesRestoring:
                    return "Restoring..."
                case .purchasesRecoveredExplanation:
                    return "We restored your past purchases and applied them to your account."
                case .purchasesNotFound:
                    return "No past purchases"
                case .purchasesNotRecoveredExplanation:
                    return "We could not find any purchases with your account. " +
                    "If you think this is an error, please contact support."
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
                case .done:
                    return "Done"
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
                    return "You have an active subscription that was purchased on the web."
                    + " You can manage your subscription using the button below."
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
                case .historyLatestPurchaseDate:
                    return "Latest Purchase Date"
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
                case .cardStorePromotional:
                    return "Via Support"
                case .storeExternal:
                    return "External Purchases"
                case .storeUnknownStore:
                    return "Unknown Store"
                case .storePaddle:
                    return "Paddle"
                case .storeWeb:
                    return "Web"
                case .typeSubscription:
                    return "Subscription"
                case .typeOneTimePurchase:
                    return "One-time Purchase"
                case .debugHeaderTitle:
                    return "Debug"
                case .virtualCurrencyBalancesScreenHeader:
                    return "In-App Currencies"
                case .seeAllVirtualCurrencies:
                    return "See all in-app currencies"
                case .noVirtualCurrencyBalancesFound:
                    return "It doesn't look like you've purchased any in-app currencies."
                case .youMayHaveDuplicatedSubscriptionsTitle:
                    return "You may have duplicated subscriptions"
                case .youMayHaveDuplicatedSubscriptionsSubtitle:
                    return "You might be subscribed both on the web and through the App Store." +
                        "To avoid being charged twice, please cancel your iOS subscription in your device settings."
                case .pricePaid:
                    return "Paid {{ price }}."
                case .expiresOnDateWithoutChanges:
                    return "Expires on {{ date }} without further charges."
                case .renewsOnDateForPrice:
                    return "Renews on {{ date }} for {{ price }}."
                case .renewsOnDate:
                    return "Renews on {{ date }}."
                case .priceAfterwards:
                    return "{{ price }} afterwards."
                case .freeTrialUntilDate:
                    return "Free trial until {{ date }}."
                case .priceExpiresOnDateWithoutChanges:
                     return "{{ price }}. Expires on {{ date }} without changes."
                case .badgeLifetime:
                    return "Lifetime"
                case .badgeCancelled:
                    return "Cancelled"
                case .badgeFreeTrial:
                    return "Free trial"
                case .badgeTrialCancelled:
                    return "Cancelled trial"
                case .refundSuccess:
                    return "Apple has received the refund request"
                case .actionsSectionTitle:
                    return "Actions"
                case .subscriptionsSectionTitle:
                    return "Subscriptions"
                case .purchasesSectionTitle:
                    return "Purchases"
                case .testStore:
                    return "Test Store"
                case .supportTicketCreate:
                    return "Create a support ticket"
                case .email:
                    return "Email"
                case .enterEmail:
                    return "Enter your email"
                case .description:
                    return "Description"
                case .sent:
                    return "Message sent"
                case .supportTicketFailed:
                    return "Failed to send, please try again."
                case .submitTicket:
                    return "Submit ticket"
                case .characterCount:
                    return "{{ count }} characters"
                }
            }
        }

        @_spi(Internal) public subscript(_ key: CommonLocalizedString) -> String {
            localizedStrings[key.rawValue] ?? key.defaultValue
        }
    }

    @_spi(Internal) public struct HelpPath: Equatable {

        @_spi(Internal) public let id: String
        @_spi(Internal) public let title: String
        @_spi(Internal) public let url: URL?
        @_spi(Internal) public let openMethod: OpenMethod?
        @_spi(Internal) public let type: PathType
        @_spi(Internal) public let detail: PathDetail?
        @_spi(Internal) public let refundWindowDuration: RefundWindowDuration?
        @_spi(Internal) public let customActionIdentifier: String?

        @_spi(Internal) public init(
            id: String,
            title: String,
            url: URL? = nil,
            openMethod: OpenMethod? = nil,
            type: PathType,
            detail: PathDetail?,
            refundWindowDuration: RefundWindowDuration? = nil,
            customActionIdentifier: String? = nil
        ) {
            self.id = id
            self.title = title
            self.url = url
            self.openMethod = openMethod
            self.type = type
            self.detail = detail
            self.refundWindowDuration = refundWindowDuration
            self.customActionIdentifier = customActionIdentifier
        }

        @_spi(Internal) public enum PathDetail: Equatable {

            case promotionalOffer(PromotionalOffer)
            case feedbackSurvey(FeedbackSurvey)

        }

        @_spi(Internal) public enum RefundWindowDuration: Equatable {
            case forever
            case duration(ISODuration)
        }

        @_spi(Internal) public enum PathType: String, Equatable {

            case missingPurchase = "MISSING_PURCHASE"
            case refundRequest = "REFUND_REQUEST"
            case changePlans = "CHANGE_PLANS"
            case cancel = "CANCEL"
            case customUrl = "CUSTOM_URL"
            case customAction = "CUSTOM_ACTION"
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
                case "CUSTOM_ACTION":
                    self = .customAction
                default:
                    self = .unknown
                }
            }

        }

        @_spi(Internal) public enum OpenMethod: String, Equatable {

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

        @_spi(Internal) public struct PromotionalOffer: Equatable {

            @_spi(Internal) public let iosOfferId: String
            @_spi(Internal) public let eligible: Bool
            @_spi(Internal) public let title: String
            @_spi(Internal) public let subtitle: String
            @_spi(Internal) public let productMapping: [String: String]
            @_spi(Internal) public let crossProductPromotions: [String: CrossProductPromotion]

            @_spi(Internal) public struct CrossProductPromotion: Equatable {
                @_spi(Internal) public let storeOfferIdentifier: String
                @_spi(Internal) public let targetProductId: String

                @_spi(Internal) public init(
                    storeofferingidentifier: String,
                    targetproductid: String
                ) {
                    self.storeOfferIdentifier = storeofferingidentifier
                    self.targetProductId = targetproductid
                }
            }

            @_spi(Internal) public init(
                iosOfferId: String,
                eligible: Bool,
                title: String,
                subtitle: String,
                productMapping: [String: String],
                crossProductPromotions: [String: CrossProductPromotion] = [:]
            ) {
                self.iosOfferId = iosOfferId
                self.eligible = eligible
                self.title = title
                self.subtitle = subtitle
                self.productMapping = productMapping
                self.crossProductPromotions = crossProductPromotions
            }
        }

        @_spi(Internal) public struct FeedbackSurvey: Equatable {

            @_spi(Internal) public let title: String
            @_spi(Internal) public let options: [Option]

            @_spi(Internal) public init(title: String, options: [Option]) {
                self.title = title
                self.options = options
            }

            @_spi(Internal) public struct Option: Equatable {

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

    @_spi(Internal) public struct Appearance: Equatable {

        @_spi(Internal) public let accentColor: ColorInformation
        @_spi(Internal) public let textColor: ColorInformation
        @_spi(Internal) public let backgroundColor: ColorInformation
        @_spi(Internal) public let buttonTextColor: ColorInformation
        @_spi(Internal) public let buttonBackgroundColor: ColorInformation

        @_spi(Internal) public init(
            accentColor: ColorInformation,
            textColor: ColorInformation,
            backgroundColor: ColorInformation,
            buttonTextColor: ColorInformation,
            buttonBackgroundColor: ColorInformation
        ) {
            self.accentColor = accentColor
            self.textColor = textColor
            self.backgroundColor = backgroundColor
            self.buttonTextColor = buttonTextColor
            self.buttonBackgroundColor = buttonBackgroundColor
        }

        @_spi(Internal) public struct ColorInformation: Equatable {

            @_spi(Internal) public var light: RCColor?
            @_spi(Internal) public var dark: RCColor?

            @_spi(Internal) public init() {
                self.light = nil
                self.dark = nil
            }

            @_spi(Internal) public init(
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

    @_spi(Internal) public struct Screen: Equatable {

        @_spi(Internal) public let type: ScreenType
        @_spi(Internal) public let title: String
        @_spi(Internal) public let subtitle: String?
        @_spi(Internal) public let paths: [HelpPath]
        @_spi(Internal) public let offering: ScreenOffering?

        @_spi(Internal) public init(
            type: ScreenType,
            title: String,
            subtitle: String?,
            paths: [HelpPath],
            offering: ScreenOffering?
        ) {
            self.type = type
            self.title = title
            self.subtitle = subtitle
            self.paths = paths
            self.offering = offering
        }

        @_spi(Internal) public enum ScreenType: String, Equatable {
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

    @_spi(Internal) public struct Support: Equatable {

        @_spi(Internal) public let email: String
        @_spi(Internal) public let shouldWarnCustomerToUpdate: Bool
        @_spi(Internal) public let displayPurchaseHistoryLink: Bool
        @_spi(Internal) public let displayUserDetailsSection: Bool
        @_spi(Internal) public let displayVirtualCurrencies: Bool
        @_spi(Internal) public let shouldWarnCustomersAboutMultipleSubscriptions: Bool
        @_spi(Internal) public let supportTickets: SupportTickets?

        @_spi(Internal) public init(
            email: String,
            shouldWarnCustomerToUpdate: Bool,
            displayPurchaseHistoryLink: Bool,
            displayUserDetailsSection: Bool,
            displayVirtualCurrencies: Bool,
            shouldWarnCustomersAboutMultipleSubscriptions: Bool,
            supportTickets: SupportTickets? = nil
        ) {
            self.email = email
            self.shouldWarnCustomerToUpdate = shouldWarnCustomerToUpdate
            self.displayPurchaseHistoryLink = displayPurchaseHistoryLink
            self.displayUserDetailsSection = displayUserDetailsSection
            self.displayVirtualCurrencies = displayVirtualCurrencies
            self.shouldWarnCustomersAboutMultipleSubscriptions = shouldWarnCustomersAboutMultipleSubscriptions
            self.supportTickets = supportTickets
        }

        @_spi(Internal) public struct SupportTickets: Equatable {
            @_spi(Internal) public let allowCreation: Bool
            @_spi(Internal) public let customerType: CustomerType
            @_spi(Internal) public let customerDetails: CustomerDetails?

            @_spi(Internal) public init(
                allowCreation: Bool,
                customerType: CustomerType,
                customerDetails: CustomerDetails? = nil
            ) {
                self.allowCreation = allowCreation
                self.customerType = customerType
                self.customerDetails = customerDetails
            }

            @_spi(Internal) public enum CustomerType: String, Equatable {
                case active
                case notActive = "not_active"
                case all
                case none
            }

            @_spi(Internal) public struct CustomerDetails: Equatable {
                @_spi(Internal) public let activeEntitlements: Bool
                @_spi(Internal) public let appUserId: Bool
                @_spi(Internal) public let attConsent: Bool
                @_spi(Internal) public let country: Bool
                @_spi(Internal) public let deviceVersion: Bool
                @_spi(Internal) public let email: Bool
                @_spi(Internal) public let facebookAnonId: Bool
                @_spi(Internal) public let idfa: Bool
                @_spi(Internal) public let idfv: Bool
                @_spi(Internal) public let ipAddress: Bool
                @_spi(Internal) public let lastOpened: Bool
                @_spi(Internal) public let lastSeenAppVersion: Bool
                @_spi(Internal) public let totalSpent: Bool
                @_spi(Internal) public let userSince: Bool

                @_spi(Internal) public init(
                    activeEntitlements: Bool = false,
                    appUserId: Bool = false,
                    attConsent: Bool = false,
                    country: Bool = false,
                    deviceVersion: Bool = false,
                    email: Bool = false,
                    facebookAnonId: Bool = false,
                    idfa: Bool = false,
                    idfv: Bool = false,
                    ipAddress: Bool = false,
                    lastOpened: Bool = false,
                    lastSeenAppVersion: Bool = false,
                    totalSpent: Bool = false,
                    userSince: Bool = false
                ) {
                    self.activeEntitlements = activeEntitlements
                    self.appUserId = appUserId
                    self.attConsent = attConsent
                    self.country = country
                    self.deviceVersion = deviceVersion
                    self.email = email
                    self.facebookAnonId = facebookAnonId
                    self.idfa = idfa
                    self.idfv = idfv
                    self.ipAddress = ipAddress
                    self.lastOpened = lastOpened
                    self.lastSeenAppVersion = lastSeenAppVersion
                    self.totalSpent = totalSpent
                    self.userSince = userSince
                }
            }
        }

    }

    @_spi(Internal) public struct ChangePlan: Equatable {
        @_spi(Internal) public let groupId: String
        @_spi(Internal) public let groupName: String
        @_spi(Internal) public let products: [ChangePlanProduct]

        @_spi(Internal) public init(
            groupId: String,
            groupName: String,
            products: [ChangePlanProduct]
        ) {
            self.groupId = groupId
            self.groupName = groupName
            self.products = products
        }
    }

    @_spi(Internal) public struct ChangePlanProduct: Equatable {
        @_spi(Internal) public let productId: String
        @_spi(Internal) public let selected: Bool

        @_spi(Internal) public init(
            productId: String,
            selected: Bool
        ) {
            self.productId = productId
            self.selected = selected
        }
    }

    @_spi(Internal) public struct ScreenOffering: Equatable {
        @_spi(Internal) public let type: OfferingType
        @_spi(Internal) public let offeringId: String?
        @_spi(Internal) public let buttonText: String?

        @_spi(Internal) public init(
            type: OfferingType,
            offeringId: String?,
            buttonText: String?
        ) {
            self.type = type
            self.offeringId = offeringId
            self.buttonText = buttonText
        }

        @_spi(Internal) public enum OfferingType: String, Equatable {
            case current = "CURRENT"
            case specific = "SPECIFIC"
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
        self.changePlans = response.customerCenter.changePlans.map {
            .init(groupId: $0.groupId, groupName: $0.groupName, products: $0.products.map {
                .init(productId: $0.productId, selected: $0.selected)
            })
        }
    }

}

extension CustomerCenterConfigData.Screen {

    init(from response: CustomerCenterConfigResponse.Screen,
         localization: CustomerCenterConfigData.Localization) {
        self.type = ScreenType(from: response.type.rawValue)
        self.title = response.title
        self.subtitle = response.subtitle
        self.paths = response.paths.compactMap { CustomerCenterConfigData.HelpPath(from: $0) }
        self.offering = response.offering.map { offering in
            switch offering.type {
            case CustomerCenterConfigData.ScreenOffering.OfferingType.specific.rawValue:
                return CustomerCenterConfigData.ScreenOffering(
                    type: .specific,
                    offeringId: offering.offeringId,
                    buttonText: offering.buttonText
                )

            default:
                return CustomerCenterConfigData.ScreenOffering(
                    type: .current,
                    offeringId: nil,
                    buttonText: offering.buttonText
                )
            }
        }
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

        self.customActionIdentifier = response.actionIdentifier
    }
}

extension CustomerCenterConfigData.HelpPath.PromotionalOffer {

    init(from response: CustomerCenterConfigResponse.HelpPath.PromotionalOffer) {
        self.iosOfferId = response.iosOfferId
        self.eligible = response.eligible
        self.title = response.title
        self.subtitle = response.subtitle
        self.productMapping = response.productMapping
        self.crossProductPromotions = response.crossProductPromotions?.mapValues { CrossProductPromotion(from: $0) }
            ?? [:]
    }

}

extension CustomerCenterConfigData.HelpPath.PromotionalOffer.CrossProductPromotion {

    init(from response: CustomerCenterConfigResponse.HelpPath.PromotionalOffer.CrossProductPromotion) {
        self.storeOfferIdentifier = response.storeOfferIdentifier
        self.targetProductId = response.targetProductId
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
        self.displayUserDetailsSection = response.displayUserDetailsSection ?? true
        self.displayVirtualCurrencies = response.displayVirtualCurrencies ?? false
        self.shouldWarnCustomersAboutMultipleSubscriptions = response.shouldWarnCustomersAboutMultipleSubscriptions
            ?? false
        self.supportTickets = response.supportTickets.map { SupportTickets(from: $0) }
    }

}

extension CustomerCenterConfigData.Support.SupportTickets {

    init(from response: CustomerCenterConfigResponse.Support.SupportTickets) {
        self.allowCreation = response.allowCreation
        self.customerType = CustomerType(rawValue: response.customerType) ?? .none
        self.customerDetails = response.customerDetails.map { CustomerDetails(from: $0) }
    }

}

extension CustomerCenterConfigData.Support.SupportTickets.CustomerDetails {

    init(from response: CustomerCenterConfigResponse.Support.SupportTickets.CustomerDetails) {
        self.activeEntitlements = response.activeEntitlements ?? false
        self.appUserId = response.appUserId ?? false
        self.attConsent = response.attConsent ?? false
        self.country = response.country ?? false
        self.deviceVersion = response.deviceVersion ?? false
        self.email = response.email ?? false
        self.facebookAnonId = response.facebookAnonId ?? false
        self.idfa = response.idfa ?? false
        self.idfv = response.idfv ?? false
        self.ipAddress = response.ipAddress ?? false
        self.lastOpened = response.lastOpened ?? false
        self.lastSeenAppVersion = response.lastSeenAppVersion ?? false
        self.totalSpent = response.totalSpent ?? false
        self.userSince = response.userSince ?? false
    }

}

extension CustomerCenterConfigData.HelpPath.PathType: Sendable, Codable {}
