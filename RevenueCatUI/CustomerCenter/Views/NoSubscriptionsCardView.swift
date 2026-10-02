//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoSubscriptionsCardView.swift
//
//  Created by Facundo Menzella on 26/5/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsCardView: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.customerCenterExternalActions)
    private var externalActions: CustomerCenterExternalActions

    @StateObject
    private var viewModel: NoSubscriptionsCardViewModel

    private let title: String
    private let subtitle: String
    private let subscribeTitle: String

    init(
        title: String,
        subtitle: String,
        subscribeTitle: String,
        screenOffering: CustomerCenterConfigData.ScreenOffering?,
        purchasesProvider: CustomerCenterPurchasesType = MockCustomerCenterPurchases()
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subscribeTitle = subscribeTitle
        self._viewModel = StateObject(wrappedValue: NoSubscriptionsCardViewModel(
            screenOffering: screenOffering,
            purchasesProvider: purchasesProvider
        ))
    }

    init(
        screenOffering: CustomerCenterConfigData.ScreenOffering?,
        screen: CustomerCenterConfigData.Screen?,
        localization: CustomerCenterConfigData.Localization,
        purchasesProvider: CustomerCenterPurchasesType
    ) {
        self.init(
            title: screen?.title ?? localization[.noSubscriptionsFound],
            subtitle: screen?.subtitle ?? localization[.tryCheckRestore],
            subscribeTitle: screenOffering?.buttonText ?? localization[.buySubscrition],
            screenOffering: screenOffering,
            purchasesProvider: purchasesProvider
        )
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(alignment: .center)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
                .frame(alignment: .leading)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            if viewModel.offering != nil || viewModel.isLoadingOffering {
                Button(subscribeTitle) {
                    viewModel.showPaywall()
                }
                .buttonStyle(BuySubscriptionButtonStyle())
                .disabled(viewModel.isLoadingOffering)
                .padding(.top)
                .opacity(viewModel.isLoadingOffering ? 0 : 1.0)
                .overlay(content: {
                    if viewModel.isLoadingOffering {
                        TintedProgressView()
                    }
                })
            }
        }
        #if os(macOS)
        // A row of the grouped form the Mac lays the Customer Center out in, which draws the card.
        .padding(.vertical, 12)
        #else
        .padding(16)
        #if compiler(>=5.9)
        .background(Color(colorScheme == .light
                          ? UIColor.systemBackground
                          : UIColor.secondarySystemBackground),
                    in: .rect(cornerRadius: CustomerCenterStylingUtilities.cornerRadius))
        #endif
        #endif
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingOffering)
        .sheet(isPresented: $viewModel.showOffering, content: {
            PaywallView(
                configuration: .init(
                    offering: viewModel.offering,
                    displayCloseButton: false,
                    purchaseHandler: .default(performPurchase: viewModel.performPurchase(packageToPurchase:),
                                              performRestore: viewModel.performRestore)
                )
            )
            .onRestoreInitiated { resume in
                Task(priority: .userInitiated) { @MainActor in
                    if let restoreInitiated = self.externalActions.restoreInitiated {
                        restoreInitiated(resume)
                    } else {
                        resume()
                    }
                }
            }
            .paywallSource(.customerCenter)
            #if os(macOS)
            // iOS lets the customer swipe the paywall away; a Mac sheet has no such gesture, so it
            // gets the Customer Center's close button, floating over the paywall's corner. Not the
            // paywall's own: that one wraps the paywall in a navigation view, which the Mac draws
            // as two columns, and a Paywalls V2 design ignores it. The paywall fills the sheet, so
            // the button stays in its corner while the paywall loads.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dismissCircleButtonToolbarIfNeeded(
                navigationOptions: .default,
                floatsOverContent: true,
                customDismiss: { viewModel.showOffering = false }
            )
            #endif
            .customerCenterSheetFrame()
        })
        .onAppear {
            viewModel.refreshOffering()
        }
    }
}

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct BuySubscriptionButtonStyle: ButtonStyle {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .foregroundStyle(
                Color(colorScheme == .light
                                  ? PlatformColor.systemBackground
                                  : PlatformColor.secondarySystemBackground)
            )
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                ? appearance.tintColor(colorScheme: self.colorScheme)?.opacity(0.8)
                : appearance.tintColor(colorScheme: self.colorScheme)
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#if DEBUG
@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsCardView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            ScrollViewWithOSBackground {
                NoSubscriptionsCardView(
                    screenOffering: nil,
                    screen: CustomerCenterConfigData.default.screens[.management]!,
                    localization: CustomerCenterConfigData.default.localization,
                    purchasesProvider: MockCustomerCenterPurchases()
                )
                .padding([.leading, .trailing])
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("NoSubscriptionsCardView - No Paywall")
        }
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
