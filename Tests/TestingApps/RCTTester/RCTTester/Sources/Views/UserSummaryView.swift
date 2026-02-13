//
//  UserSummaryView.swift
//  RCTTester
//

import SwiftUI
import UIKit
import RevenueCat

struct UserSummaryView: View {

    private enum ActionState: Equatable {
        case idle
        case loading
        case showingLoginAlert
        case showingLogoutAlert
        case error(String)
    }

    @Binding var configuration: SDKConfiguration

    @State private var currentAppUserID: String = Purchases.shared.appUserID
    @State private var isAnonymous: Bool = Purchases.shared.isAnonymous
    @State private var customerInfo: CustomerInfo?
    @State private var actionState: ActionState = .idle
    @State private var newAppUserID = ""

    // MARK: - Computed Bindings

    private var showingLoginAlert: Binding<Bool> {
        Binding(
            get: { actionState == .showingLoginAlert },
            set: { if !$0 { actionState = .idle } }
        )
    }

    private var showingLogoutAlert: Binding<Bool> {
        Binding(
            get: { actionState == .showingLogoutAlert },
            set: { if !$0 { actionState = .idle } }
        )
    }

    private var showingErrorAlert: Binding<Bool> {
        Binding(
            get: {
                if case .error = actionState { return true }
                return false
            },
            set: { if !$0 { actionState = .idle } }
        )
    }

    private var errorMessage: String {
        if case .error(let message) = actionState {
            return message
        }
        return ""
    }

    private var isLoading: Bool {
        actionState == .loading
    }

    // MARK: - Body

    var body: some View {
        Group {
            // App User ID
            HStack {
                if isLoading {
                    ProgressView()
                    Text(currentAppUserID)
                        .foregroundColor(.secondary)
                } else {
                    Text(currentAppUserID)
                }

                Spacer()

                Menu {
                    Button {
                        newAppUserID = ""
                        actionState = .showingLoginAlert
                    } label: {
                        Label("Log in", systemImage: "person.badge.plus")
                    }

                    if !isAnonymous {
                        Button(role: .destructive) {
                            actionState = .showingLogoutAlert
                        } label: {
                            Label("Log out", systemImage: "person.badge.minus")
                        }
                    }

                    Divider()

                    Button {
                        UIPasteboard.general.string = currentAppUserID
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .glassEffectRegularInteractiveInCircle(fallback: { view in
                    view.padding(.trailing, -8)
                })
            }

            // Entitlements
            entitlementsRow
        }
        .task {
            await fetchCustomerInfo()
        }
        .alert("Log in", isPresented: showingLoginAlert) {
            TextField("App User ID", text: $newAppUserID)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            Button("Cancel", role: .cancel) { }
            Button("Log in") {
                Task {
                    await performLogin()
                }
            }
            .disabled(newAppUserID.isEmpty)
        } message: {
            Text("Enter the App User ID to log in as.")
        }
        .alert("Log out", isPresented: showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log out", role: .destructive) {
                Task {
                    await performLogout()
                }
            }
        } message: {
            Text("Are you sure you want to log out \(currentAppUserID)?")
        }
        .alert("Error", isPresented: showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Entitlements Row

    @ViewBuilder
    private var entitlementsRow: some View {
        HStack {
            Text("Entitlements")
                .foregroundColor(.secondary)
            Spacer()
            if let customerInfo = customerInfo {
                let activeEntitlements = customerInfo.entitlements.active
                if activeEntitlements.isEmpty {
                    Text("None")
                        .foregroundColor(.secondary)
                } else {
                    Text(activeEntitlements.keys.sorted().joined(separator: ", "))
                }
            } else {
                Text("—")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func fetchCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            print("Error fetching customer info: \(error)")
        }
    }

    private func performLogin() async {
        actionState = .loading

        do {
            let (newCustomerInfo, _) = try await Purchases.shared.logIn(newAppUserID)
            print("Logged in successfully. Customer info: \(newCustomerInfo)")

            // Update stored configuration
            configuration.appUserID = newAppUserID
            configuration.save()

            // Update customer info from response
            customerInfo = newCustomerInfo

            actionState = .idle
        } catch {
            actionState = .error(error.localizedDescription)
            print("Login error: \(error)")
        }

        updateStateFromSDK()
    }

    private func performLogout() async {
        actionState = .loading

        do {
            let newCustomerInfo = try await Purchases.shared.logOut()
            print("Logged out successfully. Customer info: \(newCustomerInfo)")

            // Clear the stored app user ID since we're now anonymous
            configuration.appUserID = ""
            configuration.save()

            // Update customer info from response
            customerInfo = newCustomerInfo

            actionState = .idle
        } catch {
            actionState = .error(error.localizedDescription)
            print("Logout error: \(error)")
        }

        updateStateFromSDK()
    }

    private func updateStateFromSDK() {
        currentAppUserID = Purchases.shared.appUserID
        isAnonymous = Purchases.shared.isAnonymous
    }
}

// MARK: - User Row

private struct UserRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    List {
        Section("User") {
            UserSummaryView(configuration: .constant(.default))
        }
    }
}
