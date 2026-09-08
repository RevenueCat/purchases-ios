//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutSheet.swift
//
//  Created by Antonio Pallares on 7/9/26.
//

#if os(iOS) && canImport(WebKit)

import SwiftUI

/// How the checkout sheet came down.
enum WebCheckoutSheetOutcome: Equatable {

    /// The page redirected to one of the return URLs it was given.
    case returned(WebCheckoutReturnStatus)

    /// The customer closed the sheet without the page saying anything.
    ///
    /// Says nothing about whether a purchase happened: the payment may have gone through moments
    /// before. Resolving that is the caller's job.
    case dismissed

    /// A sheet that goes without the page having reached a return URL was closed by the customer.
    init(returnedStatus: WebCheckoutReturnStatus?) {
        if let returnedStatus {
            self = .returned(returnedStatus)
        } else {
            self = .dismissed
        }
    }

}

@available(iOS 15.0, *)
extension View {

    /// Presents a checkout page in a sheet for as long as `viewModel` is non-`nil`.
    ///
    /// Presenting is driven by the view model rather than a flag because the checkout URL only exists
    /// once the backend has created the session, which is also when the view model can be built. A
    /// different view model presents a fresh sheet.
    ///
    /// - Parameter onOutcome: Called once per presentation, after the sheet has gone, with how it ended.
    func webCheckoutSheet(
        viewModel: Binding<WebCheckoutViewModel?>,
        onOutcome: @escaping (WebCheckoutSheetOutcome) -> Void
    ) -> some View {
        self.modifier(WebCheckoutSheetModifier(viewModel: viewModel, onOutcome: onOutcome))
    }

}

@available(iOS 15.0, *)
private struct WebCheckoutSheetModifier: ViewModifier {

    @Binding var viewModel: WebCheckoutViewModel?

    let onOutcome: (WebCheckoutSheetOutcome) -> Void

    /// Set when the page reaches a return URL, and read once the sheet has gone, to tell that apart
    /// from the customer closing the sheet. Both arrive as the same dismissal.
    @State private var returnedStatus: WebCheckoutReturnStatus?

    func body(content: Content) -> some View {
        content.sheet(item: self.$viewModel, onDismiss: self.reportOutcome) { viewModel in
            WebCheckoutView(viewModel: viewModel)
                .modifier(WebCheckoutSheetPresentation())
                .onAppear {
                    viewModel.onFinished = { status in
                        self.returnedStatus = status
                        self.viewModel = nil
                    }
                }
        }
    }

    private func reportOutcome() {
        let outcome = WebCheckoutSheetOutcome(returnedStatus: self.returnedStatus)
        self.returnedStatus = nil

        self.onOutcome(outcome)
    }

}

/// Sizing comes from detents. The page belongs to a payment provider and exposes no bridge, so it
/// cannot report its content height.
///
/// Below iOS 16.4 there are no detents and the sheet is full height.
@available(iOS 15.0, *)
private struct WebCheckoutSheetPresentation: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                // Without this a drag anywhere on the page resizes the sheet instead of scrolling the
                // checkout, which leaves fields below the fold unreachable.
                .presentationContentInteraction(.scrolls)
        } else if #available(iOS 16.0, *) {
            content.presentationDragIndicator(.visible)
        } else {
            content
        }
    }

}

/// The default `id` from `ObjectIdentifier` is what is wanted here: a new view model is a new checkout,
/// and gets its own sheet.
@available(iOS 15.0, *)
extension WebCheckoutViewModel: Identifiable {}

#endif
