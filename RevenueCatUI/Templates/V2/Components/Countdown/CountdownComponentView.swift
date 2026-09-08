//
//  CountdownComponentView.swift
//  RevenueCat
//
//  Created by Josh Holtz on 11/12/25.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.customPaywallVariables)
    private var customVariables
    @Environment(\.selectedPackageId)
    private var selectedPackageId

    @Environment(\.paywallStateValues)
    private var paywallStateValues
    @Environment(\.paywallStateDefaults)
    private var paywallStateDefaults

    private let viewModel: CountdownComponentViewModel
    private let onDismiss: () -> Void

    @StateObject private var countdownState: CountdownState

    internal init(
        viewModel: CountdownComponentViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self._countdownState = StateObject(wrappedValue: CountdownState(
            targetDate: viewModel.component.style.date,
            countFrom: viewModel.component.countFrom
        ))
    }

    private var visible: Bool {
        let currentPackage = self.packageContext.package
        return self.viewModel.visible(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(package: currentPackage),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(for: currentPackage),
            selectedPackageId: self.selectedPackageId,
            customVariables: self.customVariables,
            stateValues: self.paywallStateValues,
            stateDefaults: self.paywallStateDefaults
        )
    }

    var body: some View {
        if self.visible {
            self.countdownContent
        }
    }

    private var countdownContent: some View {
        Group {
            if let endStackViewModel = viewModel.endStackViewModel, countdownState.hasEnded {
                StackComponentView(
                    viewModel: endStackViewModel,
                    onDismiss: onDismiss
                )
            } else {
                StackComponentView(
                    viewModel: viewModel.countdownStackViewModel,
                    onDismiss: onDismiss
                )
            }
        }
        .environment(\.countdownTime, countdownState.countdownTime)
        .onAppear {
            countdownState.start()
        }
        .onDisappear {
            countdownState.stop()
        }
    }

}

// MARK: - Environment Key

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownTimeKey: EnvironmentKey {
    static let defaultValue: CountdownTime? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var countdownTime: CountdownTime? {
        get { self[CountdownTimeKey.self] }
        set { self[CountdownTimeKey.self] = newValue }
    }
}

#if DEBUG

#if swift(>=5.9)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownComponentView_Previews: PreviewProvider {

    static var previews: some View {
        // Default - Days countdown
        CountdownComponentView(
            viewModel: .init(
                component: .init(
                    style: .date(Calendar.current.date(byAdding: .day, value: 3, to: Date())!),
                    countFrom: .days,
                    countdownStack: .init(
                        components: [
                            .text(.init(
                                text: "text_1",
                                fontWeight: .bold,
                                color: .init(light: .hex("#000000")),
                                fontSize: 24
                            ))
                        ],
                        size: .init(width: .fill, height: .fit(nil)),
                        backgroundColor: .init(light: .hex("#f0f0f0")),
                        padding: .init(top: 20, bottom: 20, leading: 20, trailing: 20)
                    )
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                // swiftlint:disable:next force_try
                countdownStackViewModel: try! .init(
                    component: .init(
                        components: [
                            .text(.init(
                                text: "text_1",
                                fontWeight: .bold,
                                color: .init(light: .hex("#000000")),
                                fontSize: 24
                            ))
                        ],
                        size: .init(width: .fill, height: .fit(nil)),
                        backgroundColor: .init(light: .hex("#f0f0f0")),
                        padding: .init(top: 20, bottom: 20, leading: 20, trailing: 20)
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "text_1": .string("Offer ends in {{ count_days_with_zero }} days"
                                              + ", {{ count_hours_with_zero }} hours")
                        ]
                    ),
                    colorScheme: .light
                ),
                endStackViewModel: nil,
                fallbackStackViewModel: nil
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default - Days countdown")
    }
}

#endif

#endif

#endif
