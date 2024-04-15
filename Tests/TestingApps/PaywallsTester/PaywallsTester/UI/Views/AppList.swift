//
//  AppList.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-13.
//

import SwiftUI

struct AppList: View {
        
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
            }.navigationTitle("My Apps")
        }
    }
}

#Preview {
    AppList()
}
