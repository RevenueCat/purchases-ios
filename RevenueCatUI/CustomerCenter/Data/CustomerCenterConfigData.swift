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
import RevenueCat

struct CustomerCenterConfigData {

    let id: String
    let paths: [HelpPath]
    let title: LocalizedString

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

    struct FeedbackSurvey {

        let title: LocalizedString
        let options: [FeedbackSurveyOption]

    }

    struct FeedbackSurveyOption {

        let id: String
        let title: LocalizedString

    }

}
