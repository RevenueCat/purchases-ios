//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StickyFooterComponentView.swift
//
//  Created by Jay Shortway on 24/10/2024.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StickyFooterComponentView: View {
    private let viewModel: StickyFooterComponentViewModel

    internal init(viewModel: StickyFooterComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        EmptyView()
    }

}

#endif
