//
//  DebugErrorView.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import SwiftUI

/// A view that displays an error in debug builds
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct DebugErrorView: View {

    private let description: String
    private let releaseBehavior: ReleaseBehavior

    enum ReleaseBehavior {

        case emptyView
        case fatalError
        case replacement(AnyView)

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
                VStack {
                    self.errorView
                    view
                }

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
            .fixedSize(horizontal: false, vertical: false)
            .background(
                Color.red
                    .edgesIgnoringSafeArea(.all)
            )
            .foregroundColor(.white)
            .font(.body.bold())
            .minimumScaleFactor(0.5)
            .cornerRadius(8)
            .shadow(radius: 8)
    }

}
