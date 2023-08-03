//
//  ErrorDisplay.swift
//  
//
//  Created by Nacho Soto on 7/21/23.
//

import SwiftUI

/// A modifier that allows easily displaying an `NSError` as an `alert`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct ErrorDisplay: ViewModifier {

    @Binding
    var error: NSError?
    var dismissOnClose: Bool

    @Environment(\.dismiss)
    private var dismiss

    func body(content: Content) -> some View {
        content
            .alert(isPresented: self.isShowingError, error: self.error.map(LocalizedAlertError.init)) { _ in
                Button {
                    self.error = nil

                    if self.dismissOnClose {
                        self.dismiss()
                    }
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: { error in
                Text(error.failureReason ?? "")
            }
    }

    private var isShowingError: Binding<Bool> {
        return .init {
            self.error != nil
        } set: { newValue in
            if !newValue {
                self.error = nil
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    func displayError(_ error: Binding<NSError?>, dismissOnClose: Bool = false) -> some View {
        self.modifier(ErrorDisplay(error: error, dismissOnClose: dismissOnClose))
    }

}
