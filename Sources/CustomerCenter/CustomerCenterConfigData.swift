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

    public let paths: [HelpPath]
    public let screens: [Screen]

    public init(paths: [HelpPath], screens: [Screen]) {
        self.paths = paths
        self.screens = screens
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

            public init(iosOfferId: String) {
                self.iosOfferId = iosOfferId
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

    public struct Screen {
        public let type: ScreenType
        public let title: String
        public let subtitle: String?

        public init(type: ScreenType, title: String, subtitle: String?) {
            self.type = type
            self.title = title
            self.subtitle = subtitle
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

    public func screen(ofType type: Screen.ScreenType) -> Screen? {
        return screens.first { $0.type == type }
    }

    public subscript(type: Screen.ScreenType) -> Screen? {
        return screen(ofType: type)
    }

}

extension CustomerCenterConfigData {

    init(from response: CustomerCenterConfigResponse) {
        self.paths = response.customerCenter.paths.map { HelpPath(from: $0) }
        self.screens = response.customerCenter.screens.map { Screen(from: $0) }
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

extension CustomerCenterConfigData.Screen {

    init(from response: CustomerCenterConfigResponse.Screen) {
        self.type = ScreenType(from: response.type.rawValue)
        self.title = response.title
        self.subtitle = response.subtitle
    }

}
