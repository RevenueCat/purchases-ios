//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallStateSlotRegistry {

    enum ValueKind {
        case anyJSON
        case string
        case bool
        case packageID
    }

    static let acceptingAllForTests = PaywallStateSlotRegistry(acceptsUnknownKeys: true)

    private var expectedKinds: [PaywallStateKey: ValueKind] = [:]
    private let acceptsUnknownKeys: Bool

    init(acceptsUnknownKeys: Bool = false) {
        self.acceptsUnknownKeys = acceptsUnknownKeys
    }

    mutating func register(_ key: PaywallStateKey, kind: ValueKind) {
        self.expectedKinds[key] = kind
    }

    func accepts(_ mutation: PaywallStateMutation) -> Bool {
        guard let kind = self.expectedKinds[mutation.key] else {
            return self.acceptsUnknownKeys
        }

        guard let value = mutation.value else {
            return true
        }

        switch kind {
        case .anyJSON:
            return value.kind == .json
        case .string:
            return value.kind == .string
        case .bool:
            return value.kind == .bool
        case .packageID:
            return value.kind == .packageID
        }
    }

}

#endif
