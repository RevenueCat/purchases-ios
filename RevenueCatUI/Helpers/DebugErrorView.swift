//
//  DebugErrorView.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import SwiftUI

/// A view that displays an error in debug builds
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct DebugErrorView: View {

    private let description: String

    init(_ error: Error) {
        self.init((error as NSError).localizedDescription)
    }

    init(_ description: String) {
        self.description = description
    }

    var body: some View {
        #if DEBUG
        Text(self.description)
            .background(
                Color.red
                    .edgesIgnoringSafeArea(.all)
            )
        #else
        // Fix-me: implement a proper production error screen
        // appropriate for each case
        EmptyView()
            .onAppear {
                Logger.warning("Couldn't load paywall: \(self.description)")
            }
        #endif
    }

}
