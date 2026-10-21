//
//  RewardedAdPromptView.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
struct RewardedAdPromptView<Content: View>: View {

    @Environment(\.rewardedAdPromptDependencies) private var dependencies

    let session: RewardedAdPromptSession?
    let rewardedAd: any RewardedAdPromptAd
    let placement: String?
    let loadsRewardConfiguration: Bool
    let resultDispatcherFactory: @MainActor () -> any RewardedAdPromptResultDispatching
    let content: (RewardedAdPromptContext) -> Content

    var body: some View {
        RewardedAdPromptStateView(
            session: self.session,
            ad: self.rewardedAd,
            placement: self.placement,
            loadsRewardConfiguration: self.loadsRewardConfiguration,
            resultDispatcherFactory: self.resultDispatcherFactory,
            dependencies: self.dependencies ?? .live,
            content: self.content
        )
        .id(ObjectIdentifier(self.rewardedAd))
    }

}

@available(iOS 15.0, *)
@MainActor
private struct RewardedAdPromptStateView<Content: View>: View {

    @StateObject private var model: RewardedAdPromptModel

    private let content: (RewardedAdPromptContext) -> Content
    private let resultDispatcherFactory: @MainActor () -> any RewardedAdPromptResultDispatching
    private let session: RewardedAdPromptSession?
    private let placement: String?

    init(
        session: RewardedAdPromptSession?,
        ad rewardedAd: any RewardedAdPromptAd,
        placement: String?,
        loadsRewardConfiguration: Bool,
        resultDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptResultDispatching,
        dependencies: RewardedAdPromptDependencies,
        @ViewBuilder content: @escaping (RewardedAdPromptContext) -> Content
    ) {
        self._model = StateObject(wrappedValue: RewardedAdPromptModel(
            session: session,
            ad: rewardedAd,
            placement: placement,
            loadsRewardConfiguration: loadsRewardConfiguration,
            resultDispatcherFactory: resultDispatcherFactory,
            dependencies: dependencies
        ))
        self.content = content
        self.resultDispatcherFactory = resultDispatcherFactory
        self.session = session
        self.placement = placement
    }

    var body: some View {
        Group {
            if let context = self.model.context(resultDispatcherFactory: self.resultDispatcherFactory) {
                self.content(context)
                    .onAppear {
                        self.model.promptDidAppear(session: self.session, placement: self.placement)
                    }
            }
        }
        .background {
            RewardedAdPromptPresentationAnchor { viewController in
                self.model.setPresentationAnchor(viewController)
            }
            .frame(width: 0, height: 0)
        }
        .task {
            await self.model.loadRewardsIfNeeded()
        }
    }

}

#endif
