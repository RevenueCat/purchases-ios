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

#if CUSTOMER_CENTER_ENABLED

import Foundation
import SwiftUI

enum URLUtilities {

#if os(iOS)

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    static func createMailURLIfPossible(email: String, subject: String, body: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"

        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            return url
        }

        return nil
    }

#endif

}

#endif
