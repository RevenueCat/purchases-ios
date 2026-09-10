//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageVisibilityGraph.swift
//
//  Created by Facundo Menzella on 9/10/26.

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

/// Which components enclose each package, so selection can tell a card is off screen when the rule
/// hiding it is on a container rather than on the card itself.
///
/// Built once while the component tree is walked. Any component that can hide itself contributes a
/// node; a package records the node it was walked under.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PackageVisibilityGraph {

    private struct Node {

        let parent: Int?
        let isVisible: (Package, PackageSelectionContext) -> Bool

    }

    private var nodes: [Node] = []

    /// Returns the node children should hang off. A component that cannot hide anything contributes
    /// no node and passes `parent` straight through, so the graph only holds real gates.
    // swiftlint:disable:next function_parameter_count
    func addNode<Partial: PaywallPartialComponent & PresentedPartial>(
        parent: Int?,
        visible: Bool?,
        overrides: PaywallComponent.ComponentOverrides<Partial>?,
        visibleKeyPath: KeyPath<Partial, Bool?>,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool
    ) -> Int? {
        let gates = visible != nil
            || overrides?.contains { $0.properties[keyPath: visibleKeyPath] != nil } == true

        guard gates else {
            return parent
        }

        let presentedOverrides = overrides?.toPresentedOverrides(discardRules: discardRules)

        self.nodes.append(Node(parent: parent) { package, context in
            let conditionContext = uiConfigProvider.conditionContext(
                selectedPackageId: nil,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize
            )

            let partial = Partial.buildPartial(
                // Nothing is selected yet, since selection is what's being resolved.
                state: .default,
                condition: context.condition,
                isEligibleForIntroOffer: context.isEligibleForIntroOffer(package),
                isEligibleForPromoOffer: context.isEligibleForPromoOffer(package),
                conditionContext: conditionContext,
                with: presentedOverrides
            )

            return partial?[keyPath: visibleKeyPath] ?? visible ?? true
        })

        return self.nodes.count - 1
    }

    /// A node is on screen only if every node above it is too.
    func isVisible(node: Int?, package: Package, in context: PackageSelectionContext) -> Bool {
        var current = node

        while let index = current {
            // A package recorded against a different graph gates nothing rather than trapping.
            guard self.nodes.indices.contains(index) else {
                return true
            }

            let node = self.nodes[index]

            guard node.isVisible(package, context) else {
                return false
            }

            current = node.parent
        }

        return true
    }

}

#endif
