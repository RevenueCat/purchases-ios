//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
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
            .init(
                id: "ownmsldfow",
                title: .init(en_US: "Didn't receive purchase"),
                type: .missingPurchase,
                detail: nil
            ),
            .init(
                id: "nwodkdnfaoeb",
                title: .init(en_US: "Request a refund"),
                type: .refundRequest,
                detail: .promotionalOffer(.init(
                                iosOfferId: "rc-refund-offer",
                                eligibility: .init(firstSeen: "> 30")
                            ))
            ),
            .init(
                id: "nfoaiodifj9",
                title: .init(en_US: "Change plans"),
                type: .changePlans,
                detail: nil
            ),
            .init(
                id: "jnkasldfhas",
                title: .init(en_US: "Cancel subscription"),
                type: .cancel,
                detail: .feedbackSurvey(.init(
                                title: .init(en_US: "Why are you cancelling?"),
                                options: [
                                    .init(
                                        id: "iewrthals",
                                        title: CustomerCenterData.LocalizedString(en_US: "Too expensive"),
                                        promotionalOffer: CustomerCenterData.PromotionalOffer(
                                            iosOfferId: "rc-cancel-offer",
                                            eligibility: CustomerCenterData.Eligibility(firstSeen: "> 14")
                                        )
                                    ),
                                    .init(
                                        id: "qklpadsfj",
                                        title: CustomerCenterData.LocalizedString(en_US: "Don't use the app"),
                                        promotionalOffer: CustomerCenterData.PromotionalOffer(
                                            iosOfferId: "rc-cancel-offer",
                                            eligibility: CustomerCenterData.Eligibility(firstSeen: "> 7")
                                        )
                                    ),
                                    .init(
                                        id: "jargnapocps",
                                        title: CustomerCenterData.LocalizedString(en_US: "Bought by mistake"),
                                        promotionalOffer: nil
                                    )
                                ]
                            ))
            )
        ],
        title: .init(en_US: "How can we help?"),
        supportEmail: "support@revenuecat.com",
        appearance: .init(
            mode: .system,
            light: try! .init(stringRepresentation: "#000000"),
            dark: try! .init(stringRepresentation: "#ffffff")
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
