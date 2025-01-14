//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHistoryView.swift
//
//  Created by Facundo Menzella on 14/1/25.
//

#if os(iOS)
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct PurchaseDetailView: View {

    @StateObject var viewModel: PurchaseDetailViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.items) { detailItem in
                    CompatibilityLabeledContent(detailItem.label, content: detailItem.content)
                }
            } footer: {
                if let ownership = viewModel.localizedOwnership {
                    Text(ownership)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.didAppear()
            }
        }
    }
}

#endif
