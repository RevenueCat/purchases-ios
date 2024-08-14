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

#if CUSTOMER_CENTER_ENABLED

import RevenueCat
import SwiftUI

#if os(iOS)

/// A SwiftUI view for displaying a customer support common tasks
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CustomerCenterView: View {

    @StateObject private var viewModel: CustomerCenterViewModel

    private var localization: CustomerCenterConfigData.Localization
    private var appearance: CustomerCenterConfigData.Appearance
    private var supportInformation: CustomerCenterConfigData.Support?

    /// Create a view to handle common customer support tasks
    public init(customerCenterActionHandler: CustomerCenterActionHandler? = nil,
                localization: CustomerCenterConfigData.Localization = .default,
                appearance: CustomerCenterConfigData.Appearance = .default) {
        self._viewModel = .init(wrappedValue:
                                    CustomerCenterViewModel(customerCenterActionHandler: customerCenterActionHandler))
        self.localization = localization
        self.appearance = appearance
    }

    fileprivate init(viewModel: CustomerCenterViewModel,
                     localization: CustomerCenterConfigData.Localization = .default,
                     appearance: CustomerCenterConfigData.Appearance = .default) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.localization = localization
        self.appearance = appearance
    }

    // swiftlint:disable:next missing_docs
    public var body: some View {
        Group {
            if !self.viewModel.isLoaded {
                TintedProgressView()
            } else {
                if let configuration = self.viewModel.configuration {
                    destinationView(configuration: configuration)
                        .environment(\.localization, configuration.localization)
                        .environment(\.appearance, configuration.appearance)
                        .environment(\.supportInformation, configuration.support)
                }
            }
        }
        .task {
            await loadInformationIfNeeded()
        }
        .environmentObject(self.viewModel)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CustomerCenterView {

    func loadInformationIfNeeded() async {
        if !viewModel.isLoaded {
            await viewModel.loadHasSubscriptions()
            await viewModel.loadCustomerCenterConfig()
        }
    }

    @ViewBuilder
    func destinationView(configuration: CustomerCenterConfigData) -> some View {
        if viewModel.hasSubscriptions {
            if viewModel.subscriptionsAreFromApple,
               let screen = configuration.screens[.management] {
                ManageSubscriptionsView(screen: screen,
                                        customerCenterActionHandler: viewModel.customerCenterActionHandler)
            } else {
                WrongPlatformView()
            }
        } else {
            NoSubscriptionsView(configuration: configuration)
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterView_Previews: PreviewProvider {

   static var previews: some View {
       let viewModel = CustomerCenterViewModel(hasSubscriptions: false, areSubscriptionsFromApple: false)
       CustomerCenterView(viewModel: viewModel)
   }

}

#endif

#endif

#endif
