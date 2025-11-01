//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputSingleChoiceComponentView.swift
//
//  Created by AI Assistant
//

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct InputSingleChoiceComponentView: View {

    private let viewModel: InputSingleChoiceComponentViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: InputSingleChoiceComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        StackComponentView(
            viewModel: self.viewModel.stackViewModel,
            onDismiss: self.onDismiss
        )
    }
}

#endif
