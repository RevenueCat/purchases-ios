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

    var body: some Scene {
        WindowGroup {
            AppContentView()
                .environment(application)
        }
    }

}
