//
//  File.swift
//  
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation

struct CustomerCenterData: Decodable {

    let id: String
    let paths: [HelpPath]
    let title: LocalizedString
    let supportEmail: String
    let appearance: Appearance

    enum HelpPathType: String, Decodable {
        case missingPurchase = "MISSING_PURCHASE"
        case refundRequest = "REFUND_REQUEST"
        case changePlans = "CHANGE_PLANS"
        case cancel = "CANCEL"
        case unknown
    }

    struct HelpPath: Decodable {

        let id: String
        let title: LocalizedString
        let type: HelpPathType
        let promotionalOffer: PromotionalOffer?
        let feedbackSurvey: FeedbackSurvey?

    }

    struct LocalizedString: Decodable {

        let enUS: String

    }

    struct PromotionalOffer: Decodable {

        let iosOfferId: String
        let eligibility: Eligibility

    }

    struct Eligibility: Decodable {

        let firstSeen: String

    }

    struct FeedbackSurvey: Decodable {

        let title: LocalizedString
        let options: [FeedbackSurveyOption]

    }

    struct FeedbackSurveyOption: Decodable {

        let id: String
        let title: LocalizedString
        let promotionalOffer: PromotionalOffer?

    }

    struct Appearance: Decodable {

        let mode: String
        let light: String
        let dark: String

    }

}

extension CustomerCenterData {

    static func decode(_ json: String) -> CustomerCenterData {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(CustomerCenterData.self, from: data)
        } catch {
            fatalError("Failed to decode JSON: \(error)")
        }
    }

}
