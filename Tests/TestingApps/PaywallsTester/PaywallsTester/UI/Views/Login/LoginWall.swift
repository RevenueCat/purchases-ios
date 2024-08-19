//
//  LoginWall.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-15.
//

import SwiftUI

struct LoginWall<ContentView: View>: View {

    @EnvironmentObject private var application: ApplicationData

    @State
    private var error: Error?

    var content: (DeveloperResponse) -> ContentView
    
    var body: some View {
        switch application.authenticationStatus {
        case .unknown:
            ProgressView()
                .displayError(self.$error)
                .onAppear {
                    // note we are using .onAppear and not .task because .task causes an error dialog to
                    // briefly show when run on iOS 15.
                    Task {
                        await reload()
                    }
                }
        case let .signedIn(developer):
            content(developer)
        case .signedOut:
            LoginScreen {
                Task { @MainActor in
                    await reload()
                }
            }
            .displayError(self.$error)
        }
    }
    
    @MainActor
    private func reload() async {
        do {
            try await application.loadApplicationData()
        } catch {
            self.error = error
        }
    }
}

#Preview {
    NavigationView {
        LoginWall() { developer in
            Text("Developer \(developer.name) is now signed in.")
        }
    }
    .environmentObject(ApplicationData())
}
