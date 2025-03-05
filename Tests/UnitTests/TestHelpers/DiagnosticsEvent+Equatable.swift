//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsEvent+Equatable.swift
//
//  Created by Antonio Pallares on 28/2/25.

import Foundation
@testable import RevenueCat

// Specifying the module names silences the warning in Xcode 16+
extension RevenueCat.DiagnosticsEvent: Swift.Equatable {

    public static func == (lhs: DiagnosticsEvent, rhs: DiagnosticsEvent) -> Bool {
        return lhs.version == rhs.version &&
               lhs.eventType == rhs.eventType &&
               lhs.properties == rhs.properties &&
               lhs.timestamp == rhs.timestamp
    }

}
