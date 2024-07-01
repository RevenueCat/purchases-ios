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
import RevenueCat

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class FeedbackSurveyData: ObservableObject {

    var configuration: CustomerCenterConfigData.HelpPath.FeedbackSurvey
    var action: (() -> Void)

    init(configuration: CustomerCenterConfigData.HelpPath.FeedbackSurvey, action: @escaping (() -> Void)) {
        self.configuration = configuration
        self.action = action
    }

}

#endif
