//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import SwiftUI

@main
struct SimpleApp: App {

    init() {
        Configuration.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
    }

}
