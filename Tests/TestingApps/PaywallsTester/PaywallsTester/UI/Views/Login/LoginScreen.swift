//
//  LoginScreen.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation
import SwiftUI

struct LoginScreen: View {

    private var onAuthentication: @Sendable () -> Void

    @State
    private var model = LoginViewModel()

    init(
        onAuthentication: @Sendable @escaping () -> Void
    ) {
        self.onAuthentication = onAuthentication
    }

    var body: some View {
        VStack {
            Text("Log in to your RevenueCat account to preview the paywalls that are configured in your dashboard.")
                .font(.footnote)
                .padding()
            Form {
                Section(header: Text("Sign In")) {
                    TextField("Email", text: self.$model.username)
                        .disableAutocorrection(true)
                        .textContentType(.username)
#if !os(macOS)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
#endif
                    
                    SecureField("Password", text: self.$model.password)
                        .textContentType(.password)
                    
                    if self.model.codeRequired {
                        TextField("2FA code", text: self.$model.code)
                            .textContentType(.oneTimeCode)
                            .transition(.push(from: .bottom))
#if !os(macOS)
                            .autocapitalization(.none)
                            .keyboardType(.numberPad)
#endif
                    }
                }
                
                Section {
                    AsyncButton {
                        try await self.model.attemptLogin()
                    } label: {
                        Text("Login")
                    }
                    .disabled(!self.model.formIsComplete)
                    
                    //                AsyncButton {
                    //                    await self.model.useDemoCredentials()
                    //                } label: {
                    //                    Text("Demo credentials")
                    //                }
                }
            }
            .disabled(self.model.operationInProgress)
            .animation(.snappy(), value: self.model.codeRequired)
            .onChange(of: self.model.authenticated) { _, authenticated in
                if authenticated {
                    self.onAuthentication()
                }
            }
        }
    }

}

// MARK: - Private

@Observable
private final class LoginViewModel {

    // TODO: Is this used for anything?
//    @ObservableUserDefault(.init(key: "com.revenuecat.login.username",
//                                 defaultValue: "",
//                                 store: .revenueCatSuite))
    @ObservationIgnored
    var username: String = ""
    var password: String = ""
    var code: String = ""

    var codeRequired: Bool = false

    private(set) var operationInProgress = false
    private(set) var authenticated = false

    @MainActor
    func attemptLogin() async throws {
        self.operationInProgress = true
        defer { self.operationInProgress = false }

        do {
            try await self.authentication.logIn(user: self.username,
                                                password: self.password,
                                                code: self.code.notEmpty)

            self.authenticated = true
        } catch AuthenticationActor.Error.codeRequired {
            self.codeRequired = true
        }
    }

//    @MainActor
//    func useDemoCredentials() async {
//        self.operationInProgress = true
//        defer { self.operationInProgress = false }
//
//        await self.authentication.logInWithDemoCredentials()
//        self.authenticated = true
//    }

    var formIsComplete: Bool {
        return self.username.isNotEmpty && self.password.isNotEmpty
    }

    @ObservationIgnored
    private var authentication = AuthenticationActor()

}

// MARK: - Previews

//#Preview {
//    Container.shared.authenticationActor.register {
//        MockAuthenticationActor()
//    }
//    
//    return NavigationView {
//        LoginScreen() {
//            print("Authenticated")
//        }
//    }
//}

private final class MockAuthenticationActor: AuthenticationActorType {

    func logIn(user: String, password: String, code: String?) async throws {
        print("Mock login")
    }

    func logInWithDemoCredentials() async {
        print("Demo credentails")
    }

}
