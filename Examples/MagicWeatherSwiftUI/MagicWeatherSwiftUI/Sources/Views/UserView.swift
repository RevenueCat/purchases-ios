//
//  UserView.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import AuthenticationServices
import SwiftUI
import RevenueCat

/*
 The app's user tab to display user's details like subscription status and ID's.
 */

struct UserView: View {
    @ObservedObject var model = UserViewModel.shared

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

            Spacer()

            /// - Authentication UI
            if !Purchases.shared.isAnonymous {
                /// - Logged-in: show logout option
                Button("Logout") {
                    Task { await model.logout() }
                }
                .foregroundColor(.red)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 64.0)

            } else {
                /// - Anonymous: Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard
                            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                            let tokenData = credential.identityToken,
                            let idToken = String(data: tokenData, encoding: .utf8)
                        else {
                            model.loginError = "Failed to extract Apple ID token."
                            return
                        }
                        Task { await model.loginWithAppleIDToken(idToken) }

                    case .failure(let error):
                        let asError = error as? ASAuthorizationError
                        if asError?.code != .canceled {
                            model.loginError = error.localizedDescription
                        }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal)

                if let error = model.loginError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

            }

            /// - You should always give users the option to restore purchases
            Button("Restore Purchases") {
                Task { try? await Purchases.shared.restorePurchases() }
            }
            .foregroundColor(.blue)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 64.0)

        }.padding(.all, 16.0)
    }
}
