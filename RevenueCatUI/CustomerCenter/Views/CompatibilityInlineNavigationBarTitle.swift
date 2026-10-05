//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibilityInlineNavigationBarTitle.swift
//
//  Created by Asier G. Morato on 14/9/26.

import SwiftUI

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// `navigationBarTitleDisplayMode(.inline)` where SwiftUI offers it; a no-op on macOS, which
    /// has no navigation bar to configure.
    @ViewBuilder
    func compatibleInlineNavigationBarTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

}

#endif
