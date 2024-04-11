//
//  RootScreen.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation
import SwiftUI

public struct RootScreen: View {

    @State
    private var application = ApplicationData()

    @State
    private var error: NSError?

    public init() {}

    public var body: some View {
        self.content
//            // TODO: this doesn't work
//            .animation(.smooth(duration: 1), value: self.application.authentication)
//            .displayError(self.$error)
    }

    @MainActor
    @ViewBuilder
    private var content: some View {
        switch self.application.authentication {
        case .unknown:
            ProgressView()
                .task {
                    await self.reload()
                }

        case let .signedIn(developer):
            AppContentView()

        case .signedOut:
            LoginScreen {
                Task {
                    await self.reload()
                }
            }
        }
    }

    @MainActor
    private func reload() async {
        do {
            try await self.application.loadApplicationData()
        } catch {
            self.error = error as NSError
        }
    }

    private static let transition: AnyTransition =
        .opacity
        .animation(.smooth)

}

