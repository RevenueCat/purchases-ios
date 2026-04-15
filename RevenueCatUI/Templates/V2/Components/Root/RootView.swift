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
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentInteractionLogger)
    private var componentInteractionLogger

    private let viewModel: RootViewModel
    private let onDismiss: () -> Void
    private let defaultPackage: Package?

    @State private var sheetViewModel: SheetViewModel?
    @State private var packageSelectionSheetComponentName: String?

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
            StackComponentView(
                viewModel: viewModel.stackViewModel,
                isScrollableByDefault: true,
                onDismiss: onDismiss
            )

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
        .bottomSheet(
            sheet: $sheetViewModel,
            safeAreaInsets: self.safeAreaInsets,
            onSheetContentAppear: {
                guard let sheetViewModel else { return }
                self.componentInteractionLogger(
                    .paywallPackageSelectionSheetOpen(
                        sheetComponentName: sheetViewModel.sheet.name,
                        rootSelectedPackage: self.packageContext.package
                    )
                )
            }
        )
        .onChangeOf(sheetViewModel) { newValue in
            if let newValue {
                self.packageSelectionSheetComponentName = newValue.sheet.name
            } else {
                // Reset package selection when sheet is dismissed; snapshot sheet name before clear for analytics.
                let selectionInSheetContext = self.packageContext.package
                self.packageContext.package = self.defaultPackage
                let resultingRootPackage = self.packageContext.package
                let sheetName = self.packageSelectionSheetComponentName
                self.packageSelectionSheetComponentName = nil
                self.componentInteractionLogger(
                    .paywallPackageSelectionSheetClose(
                        sheetComponentName: sheetName,
                        sheetSelectedPackage: selectionInSheetContext,
                        resultingRootPackage: resultingRootPackage
                    )
                )
            }
        }
    }

}

#endif
