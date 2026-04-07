//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootView.swift
//
//  Created by Jay Shortway on 24/10/2024.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @EnvironmentObject
    private var packageContext: PackageContext

    private let viewModel: RootViewModel
    private let onDismiss: () -> Void
    private let defaultPackage: Package?

    @State private var headerHeight: CGFloat = 0
    @State private var sheetViewModel: SheetViewModel?

    internal init(
        viewModel: RootViewModel,
        onDismiss: @escaping () -> Void,
        defaultPackage: Package?
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.defaultPackage = defaultPackage
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .top) {
                StackComponentView(
                    viewModel: viewModel.stackViewModel,
                    isScrollableByDefault: true,
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: viewModel.headerViewModel == nil ? 0 : self.headerHeight,
                        leading: 0,
                        bottom: viewModel.headerViewModel != nil && viewModel.stickyFooterViewModel == nil
                        ? safeAreaInsets.bottom
                        : 0,
                        trailing: 0
                    )
                )

                if let headerViewModel = viewModel.headerViewModel {
                    HeaderComponentView(
                        viewModel: headerViewModel,
                        onDismiss: onDismiss
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .onSizeChange { size in
                        self.headerHeight = size.height
                    }
                }
            }

            if let stickyFooterViewModel = viewModel.stickyFooterViewModel {
                StackComponentView(
                    viewModel: stickyFooterViewModel.stackViewModel,
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: safeAreaInsets.bottom,
                        trailing: 0
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .environment(\.openSheet, { sheet in
            self.sheetViewModel = sheet
        })
        .bottomSheet(sheet: $sheetViewModel, safeAreaInsets: self.safeAreaInsets)
        .onChangeOf(sheetViewModel) { newValue in
            if newValue == nil {
                // Reset package selection to default when sheet is dismissed to prevent
                // purchasing a hidden package that was selected in the sheet
                packageContext.package = defaultPackage
            }
        }
    }

}

#endif
