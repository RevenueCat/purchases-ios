//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeedbackSurveyData.swift
//
//
//  Created by Cesar de la Vega on 14/6/24.
//

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FeedbackSurveyData: Equatable {

    let productIdentifier: String?
    let configuration: CustomerCenterConfigData.HelpPath.FeedbackSurvey
    let path: CustomerCenterConfigData.HelpPath
    let onOptionSelected: (() -> Void)

    init(
        productIdentifier: String?,
        configuration: CustomerCenterConfigData.HelpPath.FeedbackSurvey,
        path: CustomerCenterConfigData.HelpPath,
        onOptionSelected: @escaping (() -> Void
        )
    ) {
        self.productIdentifier = productIdentifier
        self.configuration = configuration
        self.path = path
        self.onOptionSelected = onOptionSelected
    }

    static func == (lhs: FeedbackSurveyData, rhs: FeedbackSurveyData) -> Bool {
        return lhs.configuration == rhs.configuration &&
        lhs.path == rhs.path &&
        lhs.productIdentifier == rhs.productIdentifier
    }
}

#endif
