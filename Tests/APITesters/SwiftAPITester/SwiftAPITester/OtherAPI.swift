//
//  OtherAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 5/31/23.
//

import Foundation

import SwiftUI

#if DEBUG && os(iOS)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct AppView: View {

    @State private var debugOverlayVisible: Bool = false

    var body: some View {
        EmptyView()
            .debugRevenueCatOverlay()
            .debugRevenueCatOverlay(isPresented: self.$debugOverlayVisible)
    }

}

#endif
