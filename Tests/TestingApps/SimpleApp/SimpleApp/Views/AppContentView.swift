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
            VStack(spacing: 20) {
                Text(verbatim: "Welcome to the Simple App")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)

                if let info = self.customerInfo {
                    Text(verbatim: "You're signed in: \(info.originalAppUserId)")
                        .font(.callout)

                    if let date = info.latestExpirationDate {
                        Text(verbatim: "Your subscription expires: \(date.formatted())")
                            .font(.caption)
                    }
                }
            }
            .padding()

            Rectangle()
                .foregroundStyle(.orange.gradient)
                .opacity(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
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
