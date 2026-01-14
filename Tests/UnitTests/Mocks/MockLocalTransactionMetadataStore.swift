//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockLocalTransactionMetadataStore.swift
//
//  Created by Antonio Pallares on 12/1/26.

import Foundation
@testable import RevenueCat

final class MockLocalTransactionMetadataStore: LocalTransactionMetadataStoreType {

    // MARK: - storeMetadata

    let invokedStoreMetadata: Atomic<Bool> = false
    let invokedStoreMetadataCount: Atomic<Int> = .init(0)
    let invokedStoreMetadataParameters: Atomic<(metadata: LocalTransactionMetadata, transactionId: String)?> = nil
    let invokedStoreMetadataParametersList: Atomic<[(
        metadata: LocalTransactionMetadata,
        transactionId: String
    )]> = .init([])

    // MARK: - getMetadata

    let invokedGetMetadata: Atomic<Bool> = false
    let invokedGetMetadataCount: Atomic<Int> = .init(0)
    let invokedGetMetadataTransactionId: Atomic<String?> = nil
    let invokedGetMetadataTransactionIdList: Atomic<[String]> = .init([])

    // MARK: - removeMetadata

    let invokedRemoveMetadata: Atomic<Bool> = false
    let invokedRemoveMetadataCount: Atomic<Int> = .init(0)
    let invokedRemoveMetadataTransactionId: Atomic<String?> = nil
    let invokedRemoveMetadataTransactionIdList: Atomic<[String]> = .init([])

    // MARK: - Storage

    private let storedMetadata: Atomic<[String: LocalTransactionMetadata]> = .init([:])

    // MARK: - LocalTransactionMetadataStoreType

    func storeMetadata(_ metadata: LocalTransactionMetadata, forTransactionId transactionId: String) {
        self.invokedStoreMetadata.value = true
        self.invokedStoreMetadataCount.modify { $0 += 1 }
        self.invokedStoreMetadataParameters.value = (metadata, transactionId)
        self.invokedStoreMetadataParametersList.modify {
            $0.append((metadata, transactionId))
        }

        self.storedMetadata.modify {
            $0[transactionId] = metadata
        }
    }

    func getMetadata(forTransactionId transactionId: String) -> LocalTransactionMetadata? {
        self.invokedGetMetadata.value = true
        self.invokedGetMetadataCount.modify { $0 += 1 }
        self.invokedGetMetadataTransactionId.value = transactionId
        self.invokedGetMetadataTransactionIdList.modify {
            $0.append(transactionId)
        }

        return self.storedMetadata.value[transactionId]
    }

    func removeMetadata(forTransactionId transactionId: String) {
        self.invokedRemoveMetadata.value = true
        self.invokedRemoveMetadataCount.modify { $0 += 1 }
        self.invokedRemoveMetadataTransactionId.value = transactionId
        self.invokedRemoveMetadataTransactionIdList.modify {
            $0.append(transactionId)
        }

        self.storedMetadata.modify {
            $0.removeValue(forKey: transactionId)
        }
    }

}
