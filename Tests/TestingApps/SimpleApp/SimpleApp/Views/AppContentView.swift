//
//  AppContentView.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    var customerInfo: CustomerInfo?

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.orange.gradient)
                .opacity(0.05)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                if let info = self.customerInfo {
                    Text(verbatim: "You're signed in: \(info.originalAppUserId)")
                        .font(.callout)

                    if !info.hasPro {
                        PaywallView(mode: .banner)
                    }

                    Spacer()

                    BarChartView(data: (0..<10).map { _ in Double.random(in: 0..<100)})
                        .frame(maxWidth: .infinity)

                    if !info.hasPro {
                        PaywallView(mode: .medium)
                    } else if let date = info.latestExpirationDate {
                        Text(verbatim: "Your subscription expires: \(date.formatted())")
                            .font(.caption)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Simple App")
        }
    }

}


#if DEBUG

@testable import RevenueCatUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct AppContentView_Previews: PreviewProvider {

    static var previews: some View {
        AppContentView(customerInfo: TestData.customerInfo)
    }

}

#endif
