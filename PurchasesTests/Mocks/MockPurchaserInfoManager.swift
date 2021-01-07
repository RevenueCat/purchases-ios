//
// Created by Andrés Boedo on 1/7/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import PurchasesCoreSwift

class MockPurchaserInfoManager: PurchaserInfoManager {
    override var delegate: PurchaserInfoManagerDelegate? {
        get { super.delegate }
        set { super.delegate = newValue }
    }

    convenience override init() {
        self.init(operationDispatcher: MockOperationDispatcher(),
                  deviceCache: MockDeviceCache(),
                  backend: MockBackend(),
                  systemInfo: RCSystemInfo(platformFlavor: "iOS",
                                           platformFlavorVersion: "1.2.3",
                                           finishTransactions: true))
    }

    override init(operationDispatcher: OperationDispatcher,
                  deviceCache: RCDeviceCache,
                  backend: RCBackend,
                  systemInfo: RCSystemInfo) {
        super.init(operationDispatcher: operationDispatcher,
                   deviceCache: deviceCache,
                   backend: backend,
                   systemInfo: systemInfo)
    }

    override func fetchAndCachePurchaserInfo(withAppUserID appUserID: String,
                                             isAppBackgrounded: Bool,
                                             completion: Purchases.ReceivePurchaserInfoBlock?) {
        super.fetchAndCachePurchaserInfo(
            withAppUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded,
            completion: completion)
    }

    override func fetchAndCachePurchaserInfoIfStale(withAppUserID appUserID: String,
                                                    isAppBackgrounded: Bool,
                                                    completion: Purchases.ReceivePurchaserInfoBlock?) {
        super.fetchAndCachePurchaserInfoIfStale(
            withAppUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded,
            completion: completion)
    }

    override func sendCachedPurchaserInfoIfAvailable(forAppUserID appUserID: String) {
        super.sendCachedPurchaserInfoIfAvailable(
            forAppUserID: appUserID)
    }

    override func purchaserInfo(withAppUserID appUserID: String,
                                completionBlock completion: @escaping Purchases.ReceivePurchaserInfoBlock) {
        super.purchaserInfo(
            withAppUserID: appUserID,
            completionBlock: completion)
    }

    override func readPurchaserInfoFromCache(forAppUserID appUserID: String) -> Purchases.PurchaserInfo {
        super.readPurchaserInfoFromCache(
            forAppUserID: appUserID)
    }

    override func cachePurchaserInfo(_ info: Purchases.PurchaserInfo,
                                     forAppUserID appUserID: String) {
        super.cachePurchaserInfo(info,
                                 forAppUserID: appUserID)
    }

    override func clearPurchaserInfoCache(forAppUserID appUserID: String) {
        super.clearPurchaserInfoCache(forAppUserID: appUserID)
    }
}
