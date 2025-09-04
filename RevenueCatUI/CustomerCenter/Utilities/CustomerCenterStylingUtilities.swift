//
//  CustomerCenterStylingUtilities.swift
//  RevenueCatUI
//
//  Created by Hidde van der Ploeg on 04/09/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CustomerCenterStylingUtilities {
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
