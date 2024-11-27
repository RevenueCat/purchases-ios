//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPresentationMode.swift
//
//  Created by Cesar de la Vega on 27/11/24.

import Foundation

#if os(iOS)

/// Warning: This is currently in beta and subject to change.
///
/// Presentation options to use with the [presentCustomerCenter](x-source-tag://presentCustomerCenter) View modifiers.
public enum CustomerCenterPresentationMode {

    /// Customer center presented using SwiftUI's `.sheet`.
    case sheet

    /// Customer center presented using SwiftUI's `.fullScreenCover`.
    case fullScreen

}

extension CustomerCenterPresentationMode {

    // swiftlint:disable:next missing_docs
    public static let `default`: Self = .sheet

}

extension CustomerCenterPresentationMode: Equatable, Codable, Sendable {}

#endif
