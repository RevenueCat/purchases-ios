//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageGroupComponentView.swift
//
//  Created by James Borthwick on 2024-09-06.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

class PackageSelectionManager: ObservableObject {

    @Published var selectedID: String = ""

    func select(id: String) {
        selectedID = id
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageGroupComponentView: View {

    let viewModel: PackageGroupComponentViewModel

    @StateObject
    var packageSelectionManager = PackageSelectionManager()

    var body: some View {
        VStack {
            Text("Package Group")
            ComponentsView(componentViewModels: self.viewModel.viewModels)
                .environmentObject(packageSelectionManager)
                .onAppear {
                    packageSelectionManager.selectedID = viewModel.defaultSelectedPackageID
                }
                .onChange(of: packageSelectionManager.selectedID) { newSelectedID in
                    viewModel.selectedPackageID = newSelectedID
                }
        }
    }

}

#endif
