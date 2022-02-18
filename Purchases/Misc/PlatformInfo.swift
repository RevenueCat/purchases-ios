//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformInfo.swift
//
//  Created by Josh Holtz on 2/17/22.

import Foundation

// swiftlint:disable missing_docs
extension Purchases {

    @objc(RCPlatformInfo)
    public final class PlatformInfo: NSObject {
        let flavor: String
        let version: String

        @objc public init(flavor: String, version: String) {
            self.flavor = flavor
            self.version = version
        }
    }

    @objc public static var platformInfo: PlatformInfo?

}
