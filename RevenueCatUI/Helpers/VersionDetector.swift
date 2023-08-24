//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VersionDetector.swift
//
//  Created by Nacho Soto on 8/17/23.

import Foundation

enum VersionDetector {

    static let iOS15: Bool = {
        return Self.isAtLeast(version: 15) && !Self.isAtLeast(version: 16)
    }()

    private static func isAtLeast(version: Int) -> Bool {
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(.init(majorVersion: version,
                                                                      minorVersion: 0,
                                                                      patchVersion: 0))
    }

}
