//
// CustomerCenterData.swift
//  
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat

struct CustomerCenterData {

    let id: String
    let paths: [HelpPath]
    let title: LocalizedString
    let supportEmail: String
    let appearance: Appearance

    enum HelpPathType: String {
        case missingPurchase = "MISSING_PURCHASE"
        case refundRequest = "REFUND_REQUEST"
        case changePlans = "CHANGE_PLANS"
        case cancel = "CANCEL"
        case unknown
    }

    enum HelpPathDetail {

        case promotionalOffer(PromotionalOffer)
        case feedbackSurvey(FeedbackSurvey)

    }

    struct HelpPath {

        let id: String
        let title: LocalizedString
        let type: HelpPathType
        let detail: HelpPathDetail?

    }

    struct LocalizedString {

        // swiftlint:disable:next identifier_name
        let en_US: String

    }

    struct PromotionalOffer {

        let iosOfferId: String
        let eligibility: Eligibility

    }

    struct Eligibility {

        let firstSeen: String

    }

    struct FeedbackSurvey {

        let title: LocalizedString
        let options: [FeedbackSurveyOption]

    }

    struct FeedbackSurveyOption {

        let id: String
        let title: LocalizedString
        let promotionalOffer: PromotionalOffer?

    }

    struct Appearance {

        let mode: String
        let color: PaywallColor

    }

}
