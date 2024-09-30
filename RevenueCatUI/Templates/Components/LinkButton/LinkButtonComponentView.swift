//
//  LinkButtonComponentView.swift
//
//
//  Created by James Borthwick on 2024-08-21.
//

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct LinkButtonComponentView: View {

    private let viewModel: LinkButtonComponentViewModel

    internal init(viewModel: LinkButtonComponentViewModel) {
        self.viewModel = viewModel
    }

    var url: URL {
        viewModel.url
    }

    var body: some View {
        EmptyView()
        Link(destination: url) {
            TextComponentView(viewModel: viewModel.textComponentViewModel)
                .cornerRadius(25)
        }
    }

}

#endif
