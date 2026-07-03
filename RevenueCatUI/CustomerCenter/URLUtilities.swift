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

#if os(iOS)
import UIKit

enum URLUtilities {

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

        guard let url = components.url else {
            return nil
        }

        return url
    }

    static func openURLIfNotAppExtension(_ url: URL) {
        guard !Self.isAppExtension,
              let application = Self.sharedUIApplication else {
            return
        }

        let selector = NSSelectorFromString("openURL:options:completionHandler:")
        typealias ClosureType = @convention(c) (AnyObject, Selector, NSURL, NSDictionary?, Any?) -> Void
        let methodIMP: IMP! = application.method(for: selector)
        let openURLMethod = unsafeBitCast(methodIMP, to: ClosureType.self)
        openURLMethod(application, selector, url as NSURL, nil, nil)
    }

    static func canOpenURL(_ url: URL) -> Bool {
        guard !Self.isAppExtension,
              let application = Self.sharedUIApplication else {
            return false
        }
        return application.canOpenURL(url)
    }

}

extension URL {

    var isWebLink: Bool {
        switch scheme?.lowercased() {
        case "http", "https":
            return true
        default:
            return false
        }
    }

}

private extension URLUtilities {

    static var isAppExtension: Bool {
        Bundle.main.bundlePath.hasSuffix(".appex")
    }

    static var sharedUIApplication: UIApplication? {
        return UIApplication.value(forKey: "sharedApplication") as? UIApplication
    }

}

#endif
