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

    @Environment(\.selectionState) var selectionState

    let viewModel: LinkButtonComponentViewModel

    var url: URL {
        viewModel.url(for: selectionState)
    }

    var body: some View {
        EmptyView()
        Link(destination: self.url) {
            TextComponentView(viewModel: viewModel.textComponentViewModel)
                .cornerRadius(25)
        }
    }

}

#endif
