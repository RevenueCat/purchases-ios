//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

/// A SwiftUI view for displaying a customer support common tasks
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public struct CustomerCenterView: View {

    @StateObject private var viewModel = CustomerCenterViewModel()

    /// Create a view to handle common customer support tasks
    public init() {}

    fileprivate init(viewModel: CustomerCenterViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        Group {
            if !viewModel.isLoaded {
                ProgressView()
            } else {
                destinationView()
            }
        }
        .task {
            await checkAndLoadSubscriptions()
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
private extension CustomerCenterView {

    func checkAndLoadSubscriptions() async {
        if !viewModel.isLoaded {
            await viewModel.loadHasSubscriptions()
        }
    }

    @ViewBuilder
    func destinationView() -> some View {
        if viewModel.hasSubscriptions {
            if viewModel.subscriptionsAreFromApple {
                ManageSubscriptionsView()
            } else {
                WrongPlatformView()
            }
        } else {
            NoSubscriptionsView()
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct CustomerCenterView_Previews: PreviewProvider {

   static var previews: some View {
       let viewModel = CustomerCenterViewModel(hasSubscriptions: false, areSubscriptionsFromApple: false)
       CustomerCenterView(viewModel: viewModel)
   }

}

#endif

#endif
