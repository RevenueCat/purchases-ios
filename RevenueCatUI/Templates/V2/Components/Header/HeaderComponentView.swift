//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HeaderComponentView.swift
//
//  Created by Facundo Menzella on 02/04/2026.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HeaderComponentView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    private let viewModel: HeaderComponentViewModel
    private let onDismiss: () -> Void

    init(
        viewModel: HeaderComponentViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        StackComponentView(
            viewModel: self.viewModel.stackViewModel,
            onDismiss: self.onDismiss,
            additionalPadding: .init(
                top: self.viewModel.firstItemIgnoresSafeArea ? 0 : self.safeAreaInsets.top,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
    }

}

#endif
