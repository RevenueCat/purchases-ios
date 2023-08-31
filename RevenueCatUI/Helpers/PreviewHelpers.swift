//
//  PreviewHelpers.swift
//  
//
//  Created by Nacho Soto on 7/29/23.
//

import RevenueCat
import SwiftUI

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@MainActor
enum PreviewHelpers {

    static let introEligibilityChecker: TrialOrIntroEligibilityChecker =
        .producing(eligibility: .eligible)
        .with(delay: .seconds(0.5))
    static let purchaseHandler: PurchaseHandler =
        .mock()
        .with(delay: .seconds(0.5))

}

/// Creates an easily previewable `TemplateViewType`.
/// Usage:
/// ```swift
/// PreviewableTemplate(
///   offering: TestData.testOffering
/// ) {
///   PaywallTemplate($0)
/// }
/// ```
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct PreviewableTemplate<T: TemplateViewType>: View {

    typealias Creator = @Sendable @MainActor (TemplateViewConfiguration) -> T

    private let configuration: Result<TemplateViewConfiguration, Error>
    private let presentInSheet: Bool
    private let creator: Creator

    @StateObject
    private var introEligibilityViewModel = IntroEligibilityViewModel(
        introEligibilityChecker: PreviewHelpers.introEligibilityChecker
    )

    init(
        offering: Offering,
        presentInSheet: Bool = false,
        creator: @escaping Creator
    ) {
        self.configuration = offering.paywall!.configuration(
            for: offering,
            mode: .fullScreen,
            locale: .current
        )
        self.presentInSheet = presentInSheet
        self.creator = creator
    }

    var body: some View {
        if self.presentInSheet {
            Rectangle()
                .hidden()
                .sheet(isPresented: .constant(true)) {
                    self.content
                }
        } else {
            self.content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.configuration {
        case let .success(configuration):
            self.creator(configuration)
                .environmentObject(self.introEligibilityViewModel)
                .environmentObject(PreviewHelpers.purchaseHandler)
                .task {
                    await self.introEligibilityViewModel.computeEligibility(
                        for: configuration.packages
                    )
                }

        case let .failure(error):
            DebugErrorView("Invalid configuration: \(error)",
                           releaseBehavior: .fatalError)
        }
    }

}

#endif
