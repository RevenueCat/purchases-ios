//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockMultiSeatSheetPresenter.swift
//
//  Created by Will Taylor on 11/13/26.

import Foundation
@testable import RevenueCat
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

final class MockMultiSeatSheetPresenter: MultiSeatSheetPresenterType {

    // MARK: - UIKit

    #if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(UIKit)

    struct InvitationSheetInvocation {
        let controller: UIViewController
        let subscriptionGroupID: String
    }

    private let _stubbedInvitationSheetError: Atomic<Error?> = .init(nil)
    private let _invitationSheetInvocations: Atomic<[InvitationSheetInvocation]> = .init([])

    /// The error thrown by ``presentMultiSeatInvitationSheet(from:subscriptionGroupID:)``, if any.
    var stubbedInvitationSheetError: Error? {
        get { self._stubbedInvitationSheetError.value }
        set { self._stubbedInvitationSheetError.value = newValue }
    }

    var invitationSheetInvocations: [InvitationSheetInvocation] {
        return self._invitationSheetInvocations.value
    }

    @MainActor
    func presentMultiSeatInvitationSheet(
        from controller: UIViewController,
        subscriptionGroupID: String
    ) async throws {
        self._invitationSheetInvocations.modify {
            $0.append(.init(controller: controller, subscriptionGroupID: subscriptionGroupID))
        }

        if let error = self.stubbedInvitationSheetError {
            throw error
        }
    }

    #endif

}
