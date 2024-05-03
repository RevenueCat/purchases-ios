//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import SwiftUI

@available(iOS 13.0, *)
public struct NoSubscriptionsView: View {
    public var body: some View {
        VStack {
            Text("No Subscriptions found")
                .font(.title)
                .padding()
            Text("We can try checking your Apple account for any previously purchased products")
                .font(.body)
                .padding()

            Spacer()

            
        }


    }
}

@available(iOS 13.0, *)
#Preview {
    NoSubscriptionsView()
}
