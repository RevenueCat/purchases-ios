//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import SwiftUI

@main
struct SimpleApp: App {
    
    @State
    private var application = ApplicationData()

    @State
    private var universalLinkShowing = false

    var body: some Scene {
        WindowGroup {
            AppContentView()
                .onOpenURL { URL in

                }
                .sheet(isPresented: $universalLinkShowing) {
                    LoginWall { response in
                        PaywallForID(apps: response.apps, id: "ofrng71bdfc2037") //ofrngb173f388db
                    }
                }
                .task {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        universalLinkShowing = true
                    }
                }
        }
        .environment(application)
    }

}
