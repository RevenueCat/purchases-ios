//
//  CustomButtonStyle.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct ManageSubscriptionsButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: 300)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
    }

}

@available(iOS 13.0, *)
struct CustomButtonStylePreview_Previews: PreviewProvider {

    static var previews: some View {
        Button("Didn't receive purchase") {}
            .buttonStyle(ManageSubscriptionsButtonStyle())
    }

}
