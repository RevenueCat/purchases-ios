//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProcessInfo+Extensions.swift
//
//  Created by Nacho Soto on 11/29/22.

import Foundation

enum EnvironmentKey: String {

    case XCTestConfigurationFile = "XCTestConfigurationFilePath"

}

extension ProcessInfo {

    static subscript(key: EnvironmentKey) -> String? {
        return Self.processInfo.environment[key.rawValue]
    }

}

#if DEBUG

extension ProcessInfo {

    static var isRunningUnitTests: Bool {
        return ProcessInfo[.XCTestConfigurationFile] != nil
    }

}

#endif
