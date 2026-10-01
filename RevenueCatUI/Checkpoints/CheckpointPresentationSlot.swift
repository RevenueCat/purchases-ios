//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresentationSlot.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Owns the single active checkpoint presentation token.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresentationSlot {

    struct Token: Equatable {
        fileprivate let identifier = UUID()
    }

    private var activeToken: Token?

    func claim() -> Token? {
        guard self.activeToken == nil else { return nil }

        let token = Token()
        self.activeToken = token
        return token
    }

    func contains(_ token: Token) -> Bool {
        return self.activeToken == token
    }

    @discardableResult
    func release(_ token: Token) -> Bool {
        guard self.activeToken == token else { return false }
        self.activeToken = nil
        return true
    }

}
