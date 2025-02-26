//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConsistentTierContentView.swift
//
//  Created by Nacho Soto on 2/12/24.
//

import SwiftUI

import RevenueCat

/// A wrapper view that can display content based on a selected package
/// and maintain a consistent layout when that selected *tier* changes.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ConsistentTierContentView<Content: View>: View {

    typealias MultiPackage = TemplateViewConfiguration.PackageConfiguration.MultiPackage
    typealias Creator = @Sendable @MainActor (PaywallData.Tier, MultiPackage) -> Content

    private let tiers: [PaywallData.Tier: MultiPackage]
    private let selected: PaywallData.Tier
    private let creator: Creator

    init(
        tiers: [PaywallData.Tier: MultiPackage],
        selected: PaywallData.Tier,
        @ViewBuilder creator: @escaping Creator
    ) {
        self.tiers = tiers
        self.selected = selected
        self.creator = creator
    }

    // swiftlint:disable force_unwrapping
    var body: some View {
        // We need to layout all possible tiers to accomodate for the longest text
        return ZStack {
            ForEach(Array(self.tiers.keys)) { tier in
                self.creator(tier, self.tiers[tier]!)
                    .opacity(tier.id == self.selected.id ? 1 : 0)
            }
        }
    }
    // swiftlint:enable force_unwrapping

}
