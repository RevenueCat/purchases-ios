//
//  AppList.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-13.
//

import SwiftUI

struct AppList: View {
    
    @Environment(ApplicationData.self) private var application
        
    var body: some View {
        NavigationView {
            LoginWall { developer in
                List {
                    ForEach(developer.apps, id: \.id) { app in
                        NavigationLink("\(app.name)") {
                            OfferingsList(app: app)
                        }
                    }
                }
            }
            .navigationTitle("My Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        application.signOut()
                    } label: {
                        Text("Log Out")
                    }
                    .opacity(application.isSignedIn ? 1 : 0)
                }
            }
        }
    }
}

#Preview {
    AppList()
}
