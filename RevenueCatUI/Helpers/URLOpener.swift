//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLOpener.swift
//
//  Created by Cesar de la Vega on 3/12/24.

import Foundation

#if os(iOS)
import UIKit

enum URLOpener {

    static var isAppExtension: Bool {
        Bundle.main.bundlePath.hasSuffix(".appex")
    }

    static var sharedUIApplication: UIApplication? {
        return UIApplication.value(forKey: "sharedApplication") as? UIApplication
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

#endif
