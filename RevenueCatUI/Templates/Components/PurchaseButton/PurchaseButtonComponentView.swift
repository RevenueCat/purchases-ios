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

    var body: some View {
        VStack {
            if let selectedID = selectionManager.selectedID {
                Text("Purchase for package \(selectedID)")
            }
            Button {
                print("Purchase button pressed")
            } label: {
                TextComponentView(viewModel: viewModel.textComponentViewModel)
                    .cornerRadius(25)
            }
        }

    }

}

#endif
