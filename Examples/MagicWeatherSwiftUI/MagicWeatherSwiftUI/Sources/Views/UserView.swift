//
//  UserView.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import SwiftUI
import RevenueCat

/*
 The app's user tab to display user's details like subscription status and ID's.
 */

struct UserView: View {
    @ObservedObject var model = UserViewModel.shared
    
    @State var newUserId: String = ""
    
    var body: some View {
        VStack {
            /// - The user's current app user ID and subscription status
            
            Text("Current User Identifier")
                .font(.headline)
                .padding(.bottom, 8.0)
                .padding(.top, 16.0)
            
            Text(Purchases.shared.appUserID)
            
            Text("Subscription Status")
                .font(.headline)
                .padding([.top, .bottom], 8.0)
            
            Text(model.subscriptionActive ? "Active" : "Not Active")
                .foregroundColor(model.subscriptionActive ? .green : .red)
                          
            /// - Authentication UI
            if !Purchases.shared.isAnonymous {
                /// - If the user is not anonymous, we should give them the option to logout
                
                Spacer()

                Button("Logout") {
                    Task {
                        await model.logout()
                    }
                }
                .foregroundColor(.red)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 64.0)
                
            } else {
                /// - If the user is anonymous, then give them the option to login
                
                Text("Login")
                    .font(.headline)
                    .padding([.top], 24.0)
                
                TextField("Enter App User ID", text: $newUserId) { (isEditing) in
                    
                } onCommit: {
                    guard !self.newUserId.isEmpty else { return }

                    _ = Task { await self.model.login(userId: newUserId) }
                    self.newUserId = ""
                    
                }.multilineTextAlignment(.center)
                .padding(.top, 8.0)
                
                Spacer()
            }
                       
            /// - You should always give users the option to restore purchases to connect their purchase to their current app user ID
            Button("Restore Purchases") {
                Task {
                    try? await Purchases.shared.restorePurchases()
                }
            }
            .foregroundColor(.blue)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 64.0)
            
        }.padding(.all, 16.0)
    }
}
