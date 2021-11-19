//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockIdentityManager: IdentityManager {

    var identifyError: Error?
    var aliasError: Error?
    var aliasCalled = false
    var identifyCalled = false
    var resetCalled = false
    var mockIsAnonymous = false
    var mockAppUserID: String

    init(mockAppUserID: String) {
        let mockDeviceCache = MockDeviceCache()
        let mockBackend = MockBackend()
        let mockSystemInfo = try! MockSystemInfo(platformFlavor: nil,
                                                 platformFlavorVersion: nil,
                                                 finishTransactions: false)
        self.mockAppUserID = mockAppUserID
        super.init(deviceCache: mockDeviceCache,
                   backend: mockBackend,
                   customerInfoManager: MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                                deviceCache: mockDeviceCache,
                                                                backend: mockBackend,
                                                                systemInfo: mockSystemInfo),
                   appUserID: mockAppUserID)
    }

    override var currentAppUserID: String {
        if (mockIsAnonymous) {
            return "$RCAnonymousID:ff68f26e432648369a713849a9f93b58"
        } else {
            return mockAppUserID
        }
    }

    override var currentUserIsAnonymous: Bool {
        return mockIsAnonymous
    }

}
