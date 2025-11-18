//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CreateTicketView.swift
//
//  Created by Rosie Watson on 11/10/2025

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CreateTicketView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    var navigationOptions

    @Binding
    private var isPresented: Bool

    @State
    private var email: String = ""

    @State
    private var description: String = ""

    @State
    private var isSubmitting: Bool = false

    @State
    private var errorMessage: String?

    @State
    private var hasAttemptedSubmit: Bool = false

    @FocusState
    private var focusedField: Field?

    private let purchasesProvider: CustomerCenterPurchasesType
    private let maxCharacters = 250

    init(isPresented: Binding<Bool>, purchasesProvider: CustomerCenterPurchasesType) {
        self._isPresented = isPresented
        self.purchasesProvider = purchasesProvider
    }

    private enum Field: Hashable {
        case email
        case description
    }

    private var isValidEmail: Bool {
        EmailValidator.isValid(email)
    }

    var body: some View {
        CompatibilityNavigationStack {
            Form {
                Section(header: Text(localization[.email])) {
                    TextField(localization[.enterEmail], text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .description
                        }

                    if hasAttemptedSubmit && !email.isEmpty && !isValidEmail {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text(localization[.description])) {
                    TextEditor(text: Binding(
                        get: { description },
                        set: { newValue in
                            if newValue.count <= maxCharacters {
                                description = newValue
                            }
                        }
                    ))
                        .frame(minHeight: 150)
                        .focused($focusedField, equals: .description)

                    Text(
                        localization[.characterCount]
                            .replacingOccurrences(of: "{{ count }}", with: "\(description.count)/\(maxCharacters)")
                    )
                        .font(.caption)
                        .foregroundColor(description.count >= maxCharacters ? .red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Section {
                    Button(action: submitTicket) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text(localization[.submitTicket])
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || description.isEmpty || isSubmitting)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .dismissCircleButtonToolbarIfNeeded(
                navigationOptions: navigationOptions,
                customDismiss: {
                    isPresented = false
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    Text(localization[.supportTicketCreate])
                        .font(.headline)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(localization[.done]) {
                        focusedField = nil
                    }
                }
            })
        }
    }

    private func submitTicket() {
        hasAttemptedSubmit = true
        errorMessage = nil
        focusedField = nil

        // Don't proceed if validation fails
        guard isValidEmail && !description.isEmpty else {
            return
        }

        isSubmitting = true

        Task {
            do {
                let sent = try await purchasesProvider.createTicket(
                    customerEmail: email,
                    ticketDescription: description
                )

                await MainActor.run {
                    isSubmitting = false

                    if sent {
                        Logger.debug("Support ticket submitted successfully")
                        isPresented = false
                    } else {
                        errorMessage = localization[.supportTicketFailed]
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "An error occurred: \(error.localizedDescription)"
                    Logger.error("Failed to submit support ticket: \(error)")
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CreateTicketView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CreateTicketView(
                isPresented: .constant(true),
                purchasesProvider: MockCustomerCenterPurchases()
            )
            .environment(\.localization, CustomerCenterConfigData.default.localization)
            .environment(\.appearance, CustomerCenterConfigData.default.appearance)
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Create Ticket - \(colorScheme)")
        }
    }

}

#endif

#endif
