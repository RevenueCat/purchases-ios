//
//  Views.swift
//  SimpleApp
//
//  Created by Nacho Soto on 6/15/23.
//

import SwiftUI

struct Content: View {

    var body: some View {
        Group {
        #if os(macOS) || targetEnvironment(macCatalyst) || os(xrOS)
            self.background
        #else
            self.background
                .statusBarHidden(true)
        #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    private var background: some View {
        Rectangle()
            .fill(
                Color
                    .red
                    .gradient
            )
    }

}
