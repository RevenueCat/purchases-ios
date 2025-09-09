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

/// A namespace for Customer Center UI styling utilities.
/// Provides shared constants and styling helpers across the module.
enum CustomerCenterStylingUtilities {
    /// Default corner radius for Customer Center UI components.
    /// - Returns: `26.0` on iOS 26 and later; otherwise `10`.
    static var cornerRadius: CGFloat {
#if compiler(>=6.2)
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
