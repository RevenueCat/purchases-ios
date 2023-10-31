//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// Bundle+Extensions.swift
//
//  Created by Nacho Soto on 10/31/23.
//

import Foundation

#if COCOAPODS

extension Bundle {

    static let module: Bundle = {
           let candidates = [
               Bundle.main.resourceURL,
               Bundle(for: BundleToken.self).resourceURL
           ]

           let bundleName = "RevenueCat_RevenueCatUI"

           for candidate in candidates {
               let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
               if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                   return bundle
               }
           }

           return Bundle(for: BundleToken.self)
       }()

}

private final class BundleToken {}

#endif
