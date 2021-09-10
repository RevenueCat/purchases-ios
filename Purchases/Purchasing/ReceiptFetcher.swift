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
    private let receiptBundle: Bundle

    convenience init(requestFetcher: StoreKitRequestFetcher) {
        self.init(requestFetcher: requestFetcher, bundle: .main)
    }

    init(requestFetcher: StoreKitRequestFetcher, bundle: Bundle) {
        self.requestFetcher = requestFetcher
        self.receiptBundle = bundle
    }

    func receiptData(refreshPolicy: ReceiptRefreshPolicy, completion: @escaping (Data?) -> Void) {
        if refreshPolicy == .always {
            Logger.debug(Strings.receipt.force_refreshing_receipt)
            refreshReceipt(completion)
            return
        }

        let receiptData = receiptData()
        let isReceiptEmpty = receiptData?.isEmpty ?? true

        if isReceiptEmpty && refreshPolicy == .onlyIfEmpty {
            Logger.debug(Strings.receipt.refreshing_empty_receipt)
            refreshReceipt(completion)
        } else {
            completion(receiptData)
        }
    }

}

private extension ReceiptFetcher {

    func receiptData() -> Data? {
        guard var receiptURL: URL = receiptBundle.appStoreReceiptURL else {
            Logger.debug(Strings.receipt.no_sandbox_receipt_restore)
            return nil
        }

        #if os(watchOS)
        // as of watchOS 6.2.8, there's a bug where the receipt is stored in the sandbox receipt location,
        // but the appStoreReceiptURL method returns the URL for the production receipt.
        // This code replaces "sandboxReceipt" with "receipt" as the last component of the receiptURL so that we get the
        // correct receipt.
        // This has been filed as radar FB7699277. More info in https://github.com/RevenueCat/purchases-ios/issues/207.

        let firstOSVersionWithoutBug: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 7,
                                                                                      minorVersion: 0,
                                                                                      patchVersion: 0)
        let isBelowFirstOSVersionWithoutBug = ProcessInfo.processInfo.isOperatingSystemAtLeast(firstOSVersionWithoutBug)

        if isBelowFirstOSVersionWithoutBug && SystemInfo.isSandbox {
            let receiptURLFolder: URL = receiptURL.deletingLastPathComponent()
            let productionReceiptURL: URL = receiptURLFolder.appendingPathComponent("receipt")
            receiptURL = productionReceiptURL
        }
        #endif

        guard let data: Data = try? Data(contentsOf: receiptURL) else {
            Logger.debug(Strings.receipt.unable_to_load_receipt)
            return nil
        }

        Logger.debug(Strings.receipt.loaded_receipt(url: receiptURL))

        return data
    }

    func refreshReceipt(_ completion: @escaping (Data) -> Void) {
        requestFetcher.fetchReceiptData {
            let maybeData = self.receiptData()
            guard let receiptData = maybeData,
                  !receiptData.isEmpty else {
                      Logger.appleWarning(Strings.receipt.unable_to_load_receipt)
                      completion(Data())
                      return
                  }

            completion(receiptData)
        }
    }

}
