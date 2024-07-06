//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigTestData.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat

enum CustomerCenterConfigTestData {

    @available(iOS 14.0, *)
    static let customerCenterData = CustomerCenterConfigData(
        screens: [.management:
                .init(
                    type: .management,
                    title: "Manage Subscription",
                    subtitle: "Manage your subscription details here",
                    paths: [
                        .init(
                            id: "1",
                            title: "Didn't receive purchase",
                            type: .missingPurchase,
                            detail: nil
                        ),
                        .init(
                            id: "2",
                            title: "Request a refund",
                            type: .refundRequest,
                            detail: nil
                        ),
                        .init(
                            id: "3",
                            title: "Change plans",
                            type: .changePlans,
                            detail: nil
                        ),
                        .init(
                            id: "4",
                            title: "Cancel subscription",
                            type: .cancel,
                            detail: .feedbackSurvey(.init(
                                title: "Why are you cancelling?",
                                options: [
                                    .init(
                                        id: "1",
                                        title: "Too expensive",
                                        promotionalOffer: nil
                                    ),
                                    .init(
                                        id: "2",
                                        title: "Don't use the app",
                                        promotionalOffer: nil
                                    ),
                                    .init(
                                        id: "3",
                                        title: "Bought by mistake",
                                        promotionalOffer: nil
                                    )
                                ]
                            ))
                        )
                    ]
                ),
                  .noActive: .init(
                    type: .noActive,
                    title: "No Active Subscription",
                    subtitle: "You currently have no active subscriptions",
                    paths: [
                        .init(
                            id: "9q9719171o",
                            title: "Check purchases",
                            type: .missingPurchase,
                            detail: nil
                        )
                    ]
                  )
        ],
        // swiftlint:disable force_try
        appearance: .init(
            mode: .custom(accentColor: try! RCColor(light: RCColor(stringRepresentation: "#ffffff"),
                                                    dark: try! RCColor(stringRepresentation: "#000000")),
                         backgroundColor: try! RCColor(light: RCColor(stringRepresentation: "#000000"),
                                                       dark: try! RCColor(stringRepresentation: "#ffffff")),
                         textColor: try! RCColor(light: RCColor(stringRepresentation: "#000000"),
                                                 dark: try! RCColor(stringRepresentation: "#ffffff")))
        ),
        // swiftlint:enable force_try
        localization: .init(
            locale: "en_US",
            localizedStrings: [
                "cancel": "Cancel",
                "back": "Back"
            ]
        )
    )

    static let subscriptionInformation: SubscriptionInformation = .init(
        title: "Basic",
        durationTitle: "Monthly",
        price: "$4.99 / month",
        nextRenewalString: "June 1st, 2024",
        willRenew: true,
        productIdentifier: "product_id",
        active: true
    )

}
