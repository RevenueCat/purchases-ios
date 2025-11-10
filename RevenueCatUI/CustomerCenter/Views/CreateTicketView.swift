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
//  Created by Rosie Watson on 11/10/2025.

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

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        CompatibilityNavigationStack {
            Form {
                Section(header: Text("Email")) {
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }

                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 150)
                }

                Section {
                    Button(action: submitTicket) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Submit")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || description.isEmpty || isSubmitting)
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
                    Text("Create a Ticket")
                        .font(.headline)
                }
            })
        }
    }

    private func submitTicket() {
        isSubmitting = true

        // Simulate a submission
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                Logger.debug("Support ticket submitted:")
                Logger.debug("Email: \(email)")
                Logger.debug("Description: \(description)")

                isSubmitting = false
                isPresented = false
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
            CreateTicketView(isPresented: .constant(true))
                .environment(\.localization, CustomerCenterConfigData.default.localization)
                .environment(\.appearance, CustomerCenterConfigData.default.appearance)
                .preferredColorScheme(colorScheme)
                .previewDisplayName("Create Ticket - \(colorScheme)")
        }
    }

}

#endif

#endif
