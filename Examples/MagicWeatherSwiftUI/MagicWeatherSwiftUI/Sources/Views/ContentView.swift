//
//  ContentView.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/11/21.
//

import SwiftUI

/*
 The main view to hold our weather view and user view tabs.
 */

struct ContentView: View {
    
    /* State to determine whether the paywall modal is displayed. */
    @State var paywallPresented = false

    var body: some View {
        TabView {
            NavigationView {
                WeatherView(paywallPresented: $paywallPresented)
                    .navigationTitle("✨ Magic Weather")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "sun.max.fill")
                Text("Weather")
            }
            
            NavigationView {
                UserView()
                    .navigationTitle("User")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("User")
            }
        }
        .sheet(isPresented: $paywallPresented, content: {
            PaywallView(isPresented: $paywallPresented)
        })
    }
}
