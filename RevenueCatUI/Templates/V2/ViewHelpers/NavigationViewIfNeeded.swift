//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NavigationViewIfNeeded.swift
//
//  Created by Josh Holtz on 2/8/25.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct NavigationViewIfNeeded<Content: View>: View {
    enum Status {
        case unknown
        case inNav
        case notInNav
    }

    @State private var status: Status = .unknown

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        switch status {
        case .unknown:
            Rectangle()
                .frame(width: 0, height: 0)
                .toolbar {
                    // Zero-sized detection view:
                    ZeroFrameDetectionView { isInNav in
                        // The first time we know the answer, store it
                        if status == .unknown {
                            status = isInNav ? .inNav : .notInNav
                        }
                    }
                }
        case .inNav:
            content
        case .notInNav:
            #if swift(>=5.7)
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                // Using NavigationStack is best generic solution if only need
                // to show a toolbar
                // NavigatonStack toolbars combine nicely in parent NavigationView
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
            }
            #else
            NavigationView {
                content
            }
            #endif
        }
    }
}

// This minimal subview does the environment check and calls back exactly once.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ZeroFrameDetectionView: View {
    @Environment(\.isPresented) private var isPresented
    let didDetect: (Bool) -> Void

    @State private var hasReported = false

    var body: some View {
        Rectangle()
            .frame(width: 0, height: 0)
            .onChange(of: isPresented) { newValue in
                if newValue {
                    self.report(true)
                }
            }
            .onAppear {
                // Dispatch once after SwiftUI lay out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.report(false)
                }
            }
    }

    private func report(_ value: Bool) {
        guard !self.hasReported else { return }
        self.hasReported = true
        self.didDetect(value)
    }
}
