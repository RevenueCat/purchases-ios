//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibleTopBarTrailing.swift
//
//  Created by Josh Holtz on 8/16/24.

import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal extension ToolbarItemPlacement {

    static var compatibleTopBarTrailing: ToolbarItemPlacement {
        #if swift(>=5.9) && !os(macOS)
            if #available(iOS 14.0, tvOS 14.0, watchOS 10.0, *) {
                return .topBarTrailing
            } else {
                #if !os(watchOS)
                    return .navigationBarTrailing
                #else
                    return .cancellationAction
                #endif
            }
        #else
            return .navigationBarTrailing
        #endif
    }

}

#endif
