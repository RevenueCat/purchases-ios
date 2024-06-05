//
//  TestData.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat

enum CustomerCenterTestData {

    @available(iOS 14.0, *)
    static let customerCenterData = CustomerCenterData(
        id: "ccenter_lasdlfalaowpwp",
        paths: [
            CustomerCenterData.HelpPath(
                id: "ownmsldfow",
                title: CustomerCenterData.LocalizedString(en_US: "Didn't receive purchase"),
                type: .missingPurchase,
                detail: nil
            ),
            CustomerCenterData.HelpPath(
                id: "nwodkdnfaoeb",
                title: CustomerCenterData.LocalizedString(en_US: "Request a refund"),
                type: .refundRequest,
                detail: .promotionalOffer(CustomerCenterData.PromotionalOffer(
                                iosOfferId: "rc-refund-offer",
                                eligibility: CustomerCenterData.Eligibility(firstSeen: "> 30")
                            ))
            ),
            CustomerCenterData.HelpPath(
                id: "nfoaiodifj9",
                title: CustomerCenterData.LocalizedString(en_US: "Change plans"),
                type: .changePlans,
                detail: nil
            ),
            CustomerCenterData.HelpPath(
                id: "jnkasldfhas",
                title: CustomerCenterData.LocalizedString(en_US: "Cancel subscription"),
                type: .cancel,
                detail: .feedbackSurvey(CustomerCenterData.FeedbackSurvey(
                                title: CustomerCenterData.LocalizedString(en_US: "Why are you cancelling?"),
                                options: [
                                    CustomerCenterData.FeedbackSurveyOption(
                                        id: "iewrthals",
                                        title: CustomerCenterData.LocalizedString(en_US: "Too expensive"),
                                        promotionalOffer: CustomerCenterData.PromotionalOffer(
                                            iosOfferId: "rc-cancel-offer",
                                            eligibility: CustomerCenterData.Eligibility(firstSeen: "> 14")
                                        )
                                    ),
                                    CustomerCenterData.FeedbackSurveyOption(
                                        id: "qklpadsfj",
                                        title: CustomerCenterData.LocalizedString(en_US: "Don't use the app"),
                                        promotionalOffer: CustomerCenterData.PromotionalOffer(
                                            iosOfferId: "rc-cancel-offer",
                                            eligibility: CustomerCenterData.Eligibility(firstSeen: "> 7")
                                        )
                                    ),
                                    CustomerCenterData.FeedbackSurveyOption(
                                        id: "jargnapocps",
                                        title: CustomerCenterData.LocalizedString(en_US: "Bought by mistake"),
                                        promotionalOffer: nil
                                    )
                                ]
                            ))
            )
        ],
        title: CustomerCenterData.LocalizedString(en_US: "How can we help?"),
        supportEmail: "support@revenuecat.com",
        appearance: CustomerCenterData.Appearance(
            mode: .system,
            color: PaywallColor(
                light: PaywallColor(stringLiteral: "#000000"),
                dark: PaywallColor(stringLiteral: "#ffffff")
            )
        )
    )

    static let subscriptionInformation: SubscriptionInformation = .init(
        title: "Basic",
        duration: "Monthly",
        price: "$4.99 / month",
        nextRenewal: Date(),
        willRenew: true,
        productIdentifier: "product_id",
        active: true
    )

}
