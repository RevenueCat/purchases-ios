//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallTemplate.swift
//
//  Created by Nacho Soto on 7/10/23.

import Foundation

/// The type of template used to display a paywall.
public enum PaywallTemplate: String {

    // swiftlint:disable missing_docs
    case singlePackage = "sample_1"
    case multiPackage = "sample_2"

    // swiftlint:enable missing_docs

}

extension PaywallTemplate: Codable {}
extension PaywallTemplate: Sendable {}
extension PaywallTemplate: Equatable {}
extension PaywallTemplate: CaseIterable {}
