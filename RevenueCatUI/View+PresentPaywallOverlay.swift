//
//  View+PresentPaywallOverlay.swift
//  
//
//  Created by Josh Holtz on 8/18/23.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
extension View {

    public func paywallOverlay(
        isPresented: Binding<Bool>,
        showToggleForMultiplePackages: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.paywallOverlay(
            isPresented: isPresented,
            offering: .constant(nil),
            showToggleForMultiplePackages: showToggleForMultiplePackages,
            fonts: fonts,
            introEligibility: nil,
            purchaseHandler: nil,
            purchaseCompleted: purchaseCompleted
        )
    }

    public func paywallOverlay(
        offering: Binding<Offering?>,
        showToggleForMultiplePackages: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.paywallOverlay(
            isPresented: .constant(false),
            offering: offering,
            showToggleForMultiplePackages: showToggleForMultiplePackages,
            fonts: fonts,
            introEligibility: nil,
            purchaseHandler: nil,
            purchaseCompleted: purchaseCompleted
        )
    }

    func paywallOverlay(
        isPresented: Binding<Bool>,
        offering: Binding<Offering?>,
        showToggleForMultiplePackages: Bool = false,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler? = nil,
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self
            .modifier(PresentingPaywallOverlayModifier(
                purchaseCompleted: purchaseCompleted,
                fontProvider: fonts,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler,
                showToggleForMultiplePackages: showToggleForMultiplePackages,
                isPresented: isPresented,
                offering: offering
            ))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct PresentingPaywallOverlayModifier: ViewModifier {

    var purchaseCompleted: PurchaseCompletedHandler?
    var fontProvider: PaywallFontProvider

    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

    var showToggleForMultiplePackages: Bool

    @Binding
    var isPresented: Bool

    @Binding
    var offering: Offering?

    @State
    private var actualOffering: Offering?

    @State
    private var paywallIsVisible: Bool = false

    @State
    private var paywallShouldShow: Bool = false

    @State
    private var height: CGFloat = 0

    private static let showAnimation = Animation.spring(response: 0.45, dampingFraction: 0.6)
    private static let hideAnimation = Animation.easeInOut(duration: 0.35)

    func body(content: Content) -> some View {
        Group {
            content
                .overlay(alignment: .bottom) {
                    VStack {
                        if paywallShouldShow {
                            PaywallView(
                                offering: actualOffering,
                                mode: showToggleForMultiplePackages ? .condensedFooter : .footer,
                                fonts: self.fontProvider,
                                introEligibility: self.introEligibility ?? .default(),
                                purchaseHandler: self.purchaseHandler ?? .default()
                            )
                            .onPurchaseCompleted {
                                self.purchaseCompleted?($0)
                            }
                            .onAppear {
                                // This is needed to allow the view to render hidden so the animatino is smooth
                                // There is probably bad and there is a better way to do this
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    showOverlay()
                                }
                            }
                        }
                    }
                    .onSizeChange(.vertical, { height = $0})
                    .transition(.move(edge: .bottom))
                    .offset(y: paywallIsVisible ? 0 : 300)
                    .opacity(paywallIsVisible ? 1.0 : 0)
                }
                // Used when developer request to display overlay with the default offering
                .onChange(of: isPresented, perform: { newValue in
                    if isPresented {
                        paywallShouldShow = true
                        actualOffering = nil
                    } else {
                        hideOverlay() {
                            paywallShouldShow = false
                        }
                    }
                })
                // Used when developer request overlay with a specific offering
                .onChange(of: offering, perform: { newValue in
                    if let newValue {
                        paywallShouldShow = true
                        actualOffering = newValue
                    } else {
                        hideOverlay() {
                            paywallShouldShow = false
                            actualOffering = newValue
                        }
                    }
                })
        }
    }

    private func showOverlay() {
        withAnimation(Self.showAnimation) {
            paywallIsVisible = true
        }
    }

    private func hideOverlay(completion: @escaping () -> ()) {
        let duration = 0.35
        let animation = Animation.easeInOut(duration: duration)

        Task {
            await withCheckedContinuation { continuation in
                withAnimation(animation) {
                    paywallIsVisible = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    continuation.resume()
                    completion()
                }
            }
        }
    }
}
