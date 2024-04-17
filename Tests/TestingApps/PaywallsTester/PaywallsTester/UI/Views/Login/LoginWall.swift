//
//  LoginWall.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-15.
//

import SwiftUI

struct LoginWall<ContentView: View>: View {
    
    @Environment(ApplicationData.self) private var application
    
    @State
    private var error: NSError?
    
    var content: (DeveloperResponse) -> ContentView
    
    var body: some View {
        switch application.authentication {
        case .unknown:
            ProgressView()
                .displayError(self.$error)
                .task {
                    await reload()
                }
        case let .signedIn(developer):
            content(developer)
        case .signedOut:
            LoginScreen {
                Task {
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
            self.error = error as NSError
        }
    }
}

#Preview {
    NavigationView {
        LoginWall() { developer in
            Text("Developer \(developer.name) is now signed in.")
        }
    }
}
