//
//  AppList.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-13.
//

import SwiftUI

struct AppList: View {
    
    @State
    private var application = ApplicationData()
        
    var body: some View {
        NavigationView {
            LoginWall(application: application) { developer in
                List {
                    ForEach(developer.apps, id: \.id) { app in
                        NavigationLink("\(app.name)") {
                            OfferingsList(app: app)
                        }
                    }
                }
                
            }
            .environment(application)
            .navigationTitle("My Apps")
        }
    }
}

#Preview {
    AppList()
}
