//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FlexSpacer.swift
//
//  Created by Josh Holtz on 11/1/24.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// A weighted spacer that simulates flex layout spacing behavior.
/// Creates multiple `Spacer()` instances to achieve proportional space distribution.
/// For example, `FlexSpacer(weight: 2)` will take twice as much space as `FlexSpacer(weight: 1)`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
internal struct FlexSpacer: View {
    let weight: Int

    var body: some View {
        ForEach(0..<weight, id: \.self) { _ in
            Spacer(minLength: 0)
        }
    }
}

#endif
