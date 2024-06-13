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

#if DEBUG

enum CustomerCenterConfigTestData {

    @available(iOS 14.0, *)
    static let customerCenterData = CustomerCenterConfigData(
        id: "customer_center_id",
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
                            title: "Too expensive"
                        ),
                        .init(
                            id: "2",
                            title: "Don't use the app"
                        ),
                        .init(
                            id: "3",
                            title: "Bought by mistake"
                        )
                    ]
                ))
            )
        ],
        title: "How can we help?"
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

#endif
