//
//  View+PresentRatingRequest.swift
//
//  Created by RevenueCat on 1/2/25.
//

import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
@available(watchOS, unavailable, message: "RatingRequestScreen does not support watchOS yet")
#if swift(>=5.9)
@available(visionOS, unavailable, message: "RatingRequestScreen does not support visionOS yet")
#endif
extension View {

    /// Presents the Rating Request Screen as a modal or sheet.
    ///
    /// This modifier allows you to display a rating request screen that shows app ratings and reviews.
    ///
    /// ## Example Usage:
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var isRatingRequestPresented = false
    ///
    ///     var body: some View {
    ///         Button("Show Ratings") {
    ///             isRatingRequestPresented = true
    ///         }
    ///         .presentRatingRequest(
    ///             isPresented: $isRatingRequestPresented
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that determines whether the Rating Request Screen is visible.
    ///   - configuration: Configuration for the rating request screen appearance and behavior.
    ///   - onDismiss: A callback triggered when the sheet is dismissed.
    ///
    /// - Returns: A view modified to support presenting the Rating Request Screen.
    public func presentRatingRequest(
        isPresented: Binding<Bool>,
        configuration: RatingRequestConfiguration = .default,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        return self.modifier(
            PresentingRatingRequestModifier(
                isPresented: isPresented,
                configuration: configuration,
                onDismiss: onDismiss
            )
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PresentingRatingRequestModifier: ViewModifier {

    @Binding var isPresented: Bool
    let configuration: RatingRequestConfiguration
    let onDismiss: (() -> Void)?

    init(
        isPresented: Binding<Bool>,
        configuration: RatingRequestConfiguration,
        onDismiss: (() -> Void)?
    ) {
        self._isPresented = isPresented
        self.configuration = configuration
        self.onDismiss = onDismiss
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$isPresented, onDismiss: onDismiss) {
                RatingRequestScreen(configuration: configuration)
            }
    }
}

#endif
