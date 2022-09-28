//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptFetcher.swift
//
//  Created by Javier de Martín Gil on 8/7/21.
//

import Foundation

class ReceiptFetcher {

    private let requestFetcher: StoreKitRequestFetcher
    let systemInfo: SystemInfo

    init(requestFetcher: StoreKitRequestFetcher, systemInfo: SystemInfo) {
        self.requestFetcher = requestFetcher
        self.systemInfo = systemInfo
    }

    func receiptData(refreshPolicy: ReceiptRefreshPolicy, completion: @escaping (Data?) -> Void) {
        switch refreshPolicy {
        case .always:
            Logger.debug(Strings.receipt.force_refreshing_receipt)
            self.refreshReceipt(completion)

        case .onlyIfEmpty:
            let receiptData = self.receiptData()
            let isReceiptEmpty = receiptData?.isEmpty ?? true

            if isReceiptEmpty {
                Logger.debug(Strings.receipt.refreshing_empty_receipt)
                self.refreshReceipt(completion)
            } else {
                completion(receiptData)
            }

        case .never:
            completion(self.receiptData())
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func receiptData(refreshPolicy: ReceiptRefreshPolicy) async -> Data? {
        return await withCheckedContinuation { continuation in
            receiptData(refreshPolicy: refreshPolicy) { result in
                continuation.resume(returning: result)
            }
        }
    }

}

extension ReceiptFetcher {

    var receiptURL: URL? {
        guard var receiptURL = self.systemInfo.bundle.appStoreReceiptURL else {
            Logger.debug(Strings.receipt.no_sandbox_receipt_restore)
            return nil
        }

        #if os(watchOS)
        return self.watchOSReceiptURL(receiptURL)
        #else
        return receiptURL
        #endif
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension ReceiptFetcher: @unchecked Sendable {}

// MARK: -

private extension ReceiptFetcher {

    func receiptData() -> Data? {
        guard let receiptURL = self.receiptURL else {
            return nil
        }

        guard let data: Data = try? Data(contentsOf: receiptURL) else {
            Logger.debug(Strings.receipt.unable_to_load_receipt)
            return nil
        }

        Logger.debug(Strings.receipt.loaded_receipt(url: receiptURL))

        return data
    }

    func refreshReceipt(_ completion: @escaping (Data) -> Void) {
        requestFetcher.fetchReceiptData {
            let data = self.receiptData()
            guard let receiptData = data,
                  !receiptData.isEmpty else {
                      Logger.appleWarning(Strings.receipt.unable_to_load_receipt)
                      completion(Data())
                      return
                  }

            completion(receiptData)
        }
    }

}
