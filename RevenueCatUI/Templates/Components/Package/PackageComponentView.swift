//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SpacerComponentView.swift
//
//  Created by James Borthwick on 2024-09-06.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageComponentView: View {

    let viewModel: PackageComponentViewModel

    @EnvironmentObject var selectionManager: PackageSelectionManager

    var isSelected: Bool {
        selectionManager.selectedID == viewModel.packageID
    }

    var body: some View {
        Button {
            selectionManager.selectedID = viewModel.packageID
        } label: {
            VStack {
                Text(viewModel.title)
                ComponentsView(componentViewModels:
                                isSelected ?
                               self.viewModel.selectedViewModels :
                                self.viewModel.notSelectedViewModels)
            }
        }
    }

}

#endif
