//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VisibleIfNeeded.swift
//
//  Created by Josh Holtz on 2/13/25.

import SwiftUI

struct VisibleIfNeeded<Content: View>: View {

    let visible: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if visible {
                self.content()
            }
        }
    }

}
