//
//  WrongPlatformView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
public struct WrongPlatformView: View {

    @State private var platformName: String = "unknown"

    public var body: some View {
        VStack {
            Text("Your subscription is being billed through \(platformName).")
                .font(.title)
                .padding()

            Text("Go the app settings on \(platformName) to manage your subscription and billing.")
                .padding()

            Spacer()
            Button("Open subscription settings") {
                Task {
                    try await Purchases.shared.showManageSubscriptions()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

        }
        .task {
            if let customerInfo = try? await Purchases.shared.customerInfo(),
               let firstEntitlement = customerInfo.entitlements.active.first {
//                // todo: clean up, make sure these are human-readable
                self.platformName = "\(firstEntitlement.value.store)"
            }

        }
    }

}

@available(iOS 15.0, *)
#Preview {
    WrongPlatformView()
}
