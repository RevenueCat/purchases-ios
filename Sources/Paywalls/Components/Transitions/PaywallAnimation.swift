//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallAnimation.swift
//
//  Created by Jacob Zivan Rakidzich on 8/20/25.
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    struct Animation: PaywallComponentBase {

        public let type: AnimationType
        public let msDelay: Int
        public let msDuration: Int

        init(type: AnimationType, msDelay: Int, msDuration: Int) {
            self.type = type
            self.msDelay = msDelay
            self.msDuration = msDuration
        }

    }

    /// Defines the type of animation to use for paywall transitions.
    enum AnimationType: String, PaywallComponentBase {

        case easeIn
        case easeInOut
        case easeOut
        case linear

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = AnimationType(rawValue: rawValue ?? "") ?? .easeInOut
        }

    }

}
