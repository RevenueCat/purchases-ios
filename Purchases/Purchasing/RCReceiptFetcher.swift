//
//  RCReceiptFetcher.swift
//  Purchases
//
//  Created by Javier de Martín Gil on 8/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO: Make internal after migration to Swift is complete
@objc open class RCReceiptFetcher: NSObject {

    // TODO: Make internal after migration to Swift is complete
    @objc open func receiptData() -> Data? {

        guard let receiptURL: URL = Bundle.main.appStoreReceiptURL else {
            Logger.debug(Strings.receipt.no_sandbox_receipt_restore)
            return nil
        }

        #if os(watchOS)
        // as of watchOS 6.2.8, there's a bug where the receipt is stored in the sandbox receipt location,
        // but the appStoreReceiptURL method returns the URL for the production receipt.
        // This code replaces "sandboxReceipt" with "receipt" as the last component of the receiptURL so that we get the
        // correct receipt.
        // This has been filed as radar FB7699277. More info in https://github.com/RevenueCat/purchases-ios/issues/207.

        let minimumOSVersionWithoutBug: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 7, minorVersion: 0, patchVersion: 0)
        let isBelowMinimumOSVersionWithoutBug: Bool = ProcessInfo.processInfo.isOperatingSystemAtLeast(minimumOSVersionWithoutBug)

        if isBelowMinimumOSVersionWithoutBug && RCSystemInfo.isSandbox {
            let receiptURLFolder: URL = receiptURL.lastPathComponent
            let productionReceiptURL: URL = URL(string: receiptURLFolder.appendingPathComponent("receipt"))
            receiptURL = productionReceiptURL
        }
        #endif

        guard let data: Data = try? Data(contentsOf: receiptURL) else {
            Logger.debug(Strings.receipt.unable_to_load_receipt)
            return nil
        }

        Logger.debug(String(format: Strings.receipt.loaded_receipt, receiptURL as CVarArg))

        return data
    }
}
