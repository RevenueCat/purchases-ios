//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockMultiSeatSheetsHelper.swift
//
//  Created by Will Taylor on 11/13/26.

import Foundation
@testable import RevenueCat

#if canImport(UIKit)
import UIKit
#endif

final class MockMultiSeatSheetsHelper: MultiSeatSheetsHelper {

    // MARK: - UIKit

    #if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit)

    struct InvitationSheetInvocation {
        let product: StoreProduct
        let controller: UIViewController
    }

    private let _stubbedInvitationSheetError: Atomic<Error?> = .init(nil)
    private let _invitationSheetInvocations: Atomic<[InvitationSheetInvocation]> = .init([])

    /// The error thrown by ``presentMultiSeatInvitationSheet(for:from:)``, if any.
    var stubbedInvitationSheetError: Error? {
        get { self._stubbedInvitationSheetError.value }
        set { self._stubbedInvitationSheetError.value = newValue }
    }

    var invitationSheetInvocations: [InvitationSheetInvocation] {
        return self._invitationSheetInvocations.value
    }

    @available(iOS 27.3, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(visionOS, unavailable)
    @MainActor
    override func presentMultiSeatInvitationSheet(
        for product: StoreProduct,
        from controller: UIViewController
    ) async throws {
        self._invitationSheetInvocations.modify {
            $0.append(.init(product: product, controller: controller))
        }

        if let error = self.stubbedInvitationSheetError {
            throw error
        }
    }

    #endif

}
