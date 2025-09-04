//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterStylingUtilities.swift
//
//  Created by Hidde van der Ploeg on 04/09/2025.

import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)

/// To help with different styling between iOS 26 and older
public enum CustomerCenterStylingUtilities {
    /// Default corner radius for Customer Center UI components.
    /// - Returns: `26.0` on iOS 26 and later; otherwise `10`.
    public static var cornerRadius: CGFloat {
#if swift(>=6.2)
        if #available(iOS 26.0, *) {
            26.0
        } else {
            10
        }
#else
        10
#endif
    }
}

#endif
