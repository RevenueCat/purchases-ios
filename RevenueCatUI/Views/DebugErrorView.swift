//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DebugErrorView.swift
//  
//  Created by Nacho Soto on 7/13/23.

import Foundation
import SwiftUI

/// A view that displays an error in debug builds
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct DebugErrorView<Content: View>: View {

    private let description: String
    private let releaseBehavior: ReleaseBehavior

    enum ReleaseBehavior {

        case emptyView
        case fatalError
        case replacement(Content)

    }

    init(_ error: Error, replacement content: Content) {
        self.init(
            (error as NSError).localizedDescription,
            replacement: content
        )
    }

    init(_ description: String, replacement content: Content) {
        self.description = description
        self.releaseBehavior = .replacement(content)
    }

    var body: some View {
        Group {
            switch self.releaseBehavior {
            case .emptyView:
                #if DEBUG
                self.errorView
                #else
                // Not using `EmptyView` so
                // this view can be laid out consistently.
                Rectangle()
                    .hidden()
                #endif

            case let .replacement(view):
                #if DEBUG
                view.overlay(alignment: .top) { self.errorView }
                #else
                view
                #endif

            case .fatalError:
                #if DEBUG
                self.errorView
                #else
                fatalError(self.description)
                #endif
            }
        }
        .onAppear {
            Logger.warning("Error: \(self.description)")
        }
    }

    private var errorView: some View {
        Text(self.description)
            .unredacted()
            .padding()
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Color.red
                    .edgesIgnoringSafeArea(.all)
            )
            .foregroundColor(.white)
            .font(.caption.bold())
            .minimumScaleFactor(0.5)
            .cornerRadius(8)
            .shadow(radius: 8)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension DebugErrorView where Content == AnyView {

    init(_ error: Error, releaseBehavior: ReleaseBehavior) {
        self.init(
            (error as NSError).localizedDescription,
            releaseBehavior: releaseBehavior
        )
    }

    init(_ description: String, releaseBehavior: ReleaseBehavior) {
        self.description = description
        self.releaseBehavior = releaseBehavior
    }

}
