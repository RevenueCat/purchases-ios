//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLUtilities.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import SwiftUI

enum URLUtilities {

#if os(iOS)

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    static func createMailURLIfPossible(email: String, subject: String, body: String) -> URL? {
        guard !email.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email

        var queryItems: [URLQueryItem] = []

        if !subject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: subject))
        }

        if !body.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: body))
        }

        components.queryItems = queryItems

        guard let url = components.url, UIApplication.shared.canOpenURL(url) else {
            return nil
        }

        return url
    }

#endif

}
