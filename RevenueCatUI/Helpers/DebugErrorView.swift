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
    private let releaseBehavior: ReleaseBehavior

    enum ReleaseBehavior {

        case emptyView
        case fatalError

    }

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

    var body: some View {
        #if DEBUG
        Text(self.description)
            .background(
                Color.red
                    .edgesIgnoringSafeArea(.all)
            )
        #else
        switch self.releaseBehavior {
        case .emptyView:
            EmptyView()
                .onAppear {
                    Logger.warning("Couldn't load paywall: \(self.description)")
                }

        case let .fatalError:
            fatalError(self.description)
        }
        #endif
    }

}
