//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ContactSupportButton.swift
//
//  Created by Engin Kurutepe on 08.01.25.

import SwiftUI
import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ContactSupportButton: View {
    @Environment(\.openURL)
    private var openURL
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    let support: CustomerCenterConfigData.Support?
    
    var body: some View {
        if let supportURL {
            Button(localization.commonLocalizedString(for: .contactSupport)) {
                Task {
                    openURL(supportURL)
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private var supportURL: URL? {
        guard let support else { return nil }
        let subject = self.localization.commonLocalizedString(for: .defaultSubject)
        let body = support.calculateBody(self.localization)
        return URLUtilities.createMailURLIfPossible(email: support.email,
                                                    subject: subject,
                                                    body: body)
    }
}

#endif
