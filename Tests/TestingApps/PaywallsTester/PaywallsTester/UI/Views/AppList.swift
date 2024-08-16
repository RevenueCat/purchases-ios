//
//  AppList.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-13.
//

import SwiftUI
import RevenueCat

struct AppList: View {

    @EnvironmentObject private var application: ApplicationData

    @AppStorage(UserDefaults.introEligibilityStatus) 
    private var introEligibility: IntroEligibilityStatus = .eligible

    var body: some View {
        NavigationView {
            LoginWall { developer in
                List {
                    ForEach(developer.apps, id: \.id) { app in
                        NavigationLink("\(app.name)") {
                            OfferingsList(app: app, introEligility: $introEligibility)
                                .navigationTitle("Paywalls") // TODO: Include app name in a dynamic length way
                        }
                    }
                }
                .refreshable {
                    try? await application.loadApplicationData()
                }
            }
            .navigationTitle("My Apps")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        application.signOut()
                    } label: {
                        Text("Log Out")
                    }
                    .opacity(application.isSignedIn ? 1 : 0)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    AppList()
    .environmentObject(ApplicationData())
}
