//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeedbackSurveyView.swift
//
//
//  Created by Cesar de la Vega on 12/6/24.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FeedbackSurveyView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.customerCenterPresentationMode)
    private var mode: CustomerCenterPresentationMode

    @Environment(\.navigationOptions)
    var navigationOptions

    @StateObject
    private var viewModel: FeedbackSurveyViewModel

    @Binding
    private var isPresented: Bool

    init(
        feedbackSurveyData: FeedbackSurveyData,
        purchasesProvider: CustomerCenterPurchasesType,
        actionWrapper: CustomerCenterActionWrapper,
        isPresented: Binding<Bool>
    ) {
        self._viewModel = StateObject(wrappedValue: FeedbackSurveyViewModel(
            feedbackSurveyData: feedbackSurveyData,
            purchasesProvider: purchasesProvider,
            actionWrapper: actionWrapper
        ))
        self._isPresented = isPresented
    }

    @ViewBuilder
    var content: some View {
        FeedbackSurveyButtonsView(
            options: self.viewModel.feedbackSurveyData.configuration.options,
            onOptionSelected: { option in
                await self.viewModel.handleAction(
                    for: option,
                    darkMode: self.colorScheme == .dark,
                    displayMode: self.mode,
                    dismissView: self.dismissView
                )
            },
            loadingOption: self.$viewModel.loadingOption
        )
    }

    var body: some View {
        CompatibilityNavigationStack {
            List {
                content
            }
            .dismissCircleButtonToolbarIfNeeded(
                navigationOptions: navigationOptions,
                customDismiss: {
                    isPresented = false
                }
            )
            .compatibleNavigation(
                item: $viewModel.promotionalOfferData,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) { promotionalOfferData in
                PromotionalOfferView(
                    promotionalOffer: promotionalOfferData.promotionalOffer,
                    product: promotionalOfferData.product,
                    promoOfferDetails: promotionalOfferData.promoOfferDetails,
                    purchasesProvider: self.viewModel.purchasesProvider,
                    actionWrapper: self.viewModel.actionWrapper,
                    onDismissPromotionalOfferView: { userAction in
                        Task(priority: .userInitiated) {
                            await viewModel.handleDismissPromotionalOfferView(
                                userAction,
                                dismissView: self.dismissView
                            )
                        }
                    }
                )
                .interactiveDismissDisabled()
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    Text(self.viewModel.feedbackSurveyData.configuration.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            })
        }
    }

    private func dismissView() {
        self.isPresented = false
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
// This is a duplicate of ActiveSubscriptionButtonsView. It should be unified in the near future.
struct FeedbackSurveyButtonsView: View {

    let options: [CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option]
    let onOptionSelected: (_ optionSelected: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) async -> Void

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Binding
    var loadingOption: String?

    var body: some View {
        ForEach(options, id: \.id) { option in
            AsyncButton {
                await self.onOptionSelected(option)
            } label: {
                if self.loadingOption == option.id {
                    TintedProgressView()
                } else {
                    Text(option.title)
                }
            }
            .disabled(self.loadingOption != nil)
        }
        .applyIfLet(appearance.tintColor(colorScheme: colorScheme), apply: { $0.tint($1)})
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct FeedbackSurveyView_Previews: PreviewProvider {

    static let title = "really long tile that should go to multiple lines but its getting clipped and now it does not"

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                FeedbackSurveyView(
                    feedbackSurveyData: FeedbackSurveyData(
                        productIdentifier: "",
                        configuration: CustomerCenterConfigData.HelpPath.FeedbackSurvey(
                            title: Self.title,
                            options: [
                                .init(id: "id1", title: "title1", promotionalOffer: nil),
                                .init(id: "id2", title: "title2", promotionalOffer: nil),
                                .init(id: "id3", title: "title3", promotionalOffer: nil)
                            ]
                        ),
                        path: CustomerCenterConfigData.HelpPath(
                            id: "id1",
                            title: "helpPathTitle1",
                            type: .missingPurchase,
                            detail: nil
                        ),
                        onOptionSelected: {}
                    ),
                    purchasesProvider: CustomerCenterPurchases(),
                    actionWrapper: .init(),
                    isPresented: .constant(true)
                )
                .environment(\.localization, CustomerCenterConfigData.default.localization)
                .environment(\.appearance, CustomerCenterConfigData.default.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Monthly renewing - \(colorScheme)")
        }
    }

}

#endif

#endif
