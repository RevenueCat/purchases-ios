//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackableComponent.swift
//
//  Created by Josh Holtz on 9/27/24.
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    protocol StackableComponent {

        var width: WidthSize? { get }
        var spacing: CGFloat? { get }
        var backgroundColor: ColorInfo? { get }
        var dimension: Dimension { get }
        var padding: Padding { get }
        var margin: Padding { get }
        var cornerRadiuses: CornerRadiuses? { get }
        var border: Border? { get }

    }

}

#endif
