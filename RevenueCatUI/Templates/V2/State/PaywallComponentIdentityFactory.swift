//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat

#if !os(tvOS)

// swiftlint:disable missing_docs

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallComponentIdentityFactory {

    let paywallID: String?
    private var legacyFallbackCounters: [PaywallComponent.ComponentType: Int] = [:]

    init(paywallID: String?) {
        self.paywallID = paywallID
    }

    func identity(for component: PaywallComponent.TextComponent) -> PaywallComponentIdentity {
        return self.identity(
            componentID: self.componentID(component.id, fallbackType: .text),
            type: .text,
            name: component.name
        )
    }

    func identity(for component: PaywallComponent.StackComponent) -> PaywallComponentIdentity {
        return self.identity(
            componentID: self.componentID(component.id, fallbackType: .stack),
            type: .stack,
            name: component.name
        )
    }

    func identity(for component: PaywallComponent.ButtonComponent) -> PaywallComponentIdentity {
        return self.identity(
            componentID: self.componentID(component.id, fallbackType: .button),
            type: .button,
            name: component.name
        )
    }

    func identity(for component: PaywallComponent.PackageComponent) -> PaywallComponentIdentity {
        return self.identity(
            componentID: self.componentID(component.id, fallbackType: .package),
            type: .package,
            name: component.name
        )
    }

    private func identity(
        componentID: String,
        type: PaywallComponent.ComponentType,
        name: String?
    ) -> PaywallComponentIdentity {
        return PaywallComponentIdentity(
            paywallID: self.paywallID,
            componentID: componentID,
            type: type.rawValue,
            name: name
        )
    }

    private func componentID(_ id: String?, fallbackType: PaywallComponent.ComponentType) -> String {
        guard let id, !id.isEmpty else {
            return self.nextLegacyFallbackComponentID(for: fallbackType)
        }
        return id
    }

    private func nextLegacyFallbackComponentID(for type: PaywallComponent.ComponentType) -> String {
        // Legacy payloads may not include component ids. Keep this deterministic so state keys
        // are stable across renders; modern payloads should use backend-provided component ids.
        let next = (self.legacyFallbackCounters[type] ?? 0) + 1
        self.legacyFallbackCounters[type] = next
        return "legacy_\(type.rawValue)_\(next)"
    }

}

// swiftlint:enable missing_docs

#endif
