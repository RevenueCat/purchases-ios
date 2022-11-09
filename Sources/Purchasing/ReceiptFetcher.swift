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
    private let receiptParser: ReceiptParser
    private let fileReader: FileReader

    let systemInfo: SystemInfo

    init(
        requestFetcher: StoreKitRequestFetcher,
        systemInfo: SystemInfo,
        receiptParser: ReceiptParser = .default,
        fileReader: FileReader = DefaultFileReader()
    ) {
        self.requestFetcher = requestFetcher
        self.systemInfo = systemInfo
        self.receiptParser = receiptParser
        self.fileReader = fileReader
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

        case let .retryUntilProductIsFound(productIdentifier, maximumRetries, sleepDuration):
            if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                Async.call(with: completion) {
                    await self.refreshReceipt(untilProductIsFound: productIdentifier,
                                              maximumRetries: maximumRetries,
                                              sleepDuration: sleepDuration)
                }
            } else {
                Logger.warn(Strings.receipt.receipt_retrying_mechanism_not_available)
                self.receiptData(refreshPolicy: .always, completion: completion)
            }

        case .never:
            completion(self.receiptData())
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func receiptData(refreshPolicy: ReceiptRefreshPolicy) async -> Data? {
        return await withCheckedContinuation { continuation in
            self.receiptData(refreshPolicy: refreshPolicy) { result in
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

        guard let data = self.fileReader.contents(of: receiptURL) else {
            Logger.debug(Strings.receipt.unable_to_load_receipt)
            return nil
        }

        Logger.debug(Strings.receipt.loaded_receipt(url: receiptURL))

        return data
    }

    func refreshReceipt(_ completion: @escaping (Data) -> Void) {
        self.requestFetcher.fetchReceiptData {
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

    /// `async` version of `refreshReceipt(_:)`
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func refreshReceipt() async -> Data {
        await withCheckedContinuation { continuation in
            self.refreshReceipt {
                continuation.resume(returning: $0)
            }
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    @MainActor
    private func refreshReceipt(
        untilProductIsFound productIdentifier: String,
        maximumRetries: Int,
        sleepDuration: DispatchTimeInterval
    ) async -> Data {
        var retries = 0
        var data: Data = .init()

        repeat {
            retries += 1
            data = await self.refreshReceipt()

            if !data.isEmpty {
                do {
                    let receipt = try self.receiptParser.parse(from: data)
                    if receipt.containsActivePurchase(forProductIdentifier: productIdentifier) {
                        return data
                    } else {
                        Logger.appleWarning(Strings.receipt.local_receipt_missing_purchase(
                            receipt,
                            forProductIdentifier: productIdentifier
                        ))
                    }
                } catch {
                    Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
                }
            }

            Logger.debug(Strings.receipt.retrying_receipt_fetch_after(sleepDuration: sleepDuration))
            try? await Task.sleep(nanoseconds: UInt64(sleepDuration.nanoseconds))
        } while retries <= maximumRetries && !Task.isCancelled

        return data
    }

}
