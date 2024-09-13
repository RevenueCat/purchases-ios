//
//  PurchaseButtonComponentView.swift
//
//
//  Created by James Borthwick on 2024-09-06.
//

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView: View {

    let viewModel: PurchaseButtonComponentViewModel

    @EnvironmentObject var selectionManager: PackageSelectionManager

    @State
    private var showAlert = false

    var body: some View {

            Button {
                showAlert = true
            } label: {
                TextComponentView(viewModel: viewModel.textComponentViewModel)
                    .cornerRadius(25)
            }
            .alert("Purchase", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text("Purchase for package \(selectionManager.selectedID ?? "nil")")
            }

    }

}

#endif
