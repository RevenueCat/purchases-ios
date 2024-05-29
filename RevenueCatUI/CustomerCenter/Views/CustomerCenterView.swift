//
//  CustomerCenterView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct CustomerCenterView: View {

    @StateObject private var viewModel = CustomerCenterViewModel()

    fileprivate init(viewModel: CustomerCenterViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            NavigationLink(destination: destinationView()) {
                Text("Billing and subscription help")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .task {
            await checkAndLoadSubscriptions()
        }
    }

}

@available(iOS 15.0, *)
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
struct CustomerCenterView_Previews: PreviewProvider {

   static var previews: some View {
       let viewModel = CustomerCenterViewModel(hasSubscriptions: false, areSubscriptionsFromApple: false)
       CustomerCenterView(viewModel: viewModel)
   }

}

#endif
