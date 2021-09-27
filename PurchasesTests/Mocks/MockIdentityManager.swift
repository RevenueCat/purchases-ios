//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockIdentityManager: IdentityManager {

    var configurationCalled = false
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
                                                                  systemInfo: mockSystemInfo))
    }

    override var currentAppUserID: String {
        if (mockIsAnonymous) {
            return "$RCAnonymousID:ff68f26e432648369a713849a9f93b58"
        } else {
            return mockAppUserID
        }
    }

    override func configure(appUserID: String?) {
        configurationCalled = true
    }

    override func createAlias(appUserID alias: String, completion: @escaping ((Error?) -> ())) {
        aliasCalled = true
        if (aliasError != nil) {
            completion(aliasError)
        } else {
            mockAppUserID = alias
            completion(nil)
        }
    }

    override func identify(appUserID: String, completion: @escaping ((Error?) -> ())) {
        identifyCalled = true
        if (identifyError != nil) {
            completion(identifyError)
        } else {
            mockAppUserID = appUserID
            completion(nil)
        }
    }

    override func resetAppUserID() {
        resetCalled = true
        mockAppUserID = "$RCAnonymousID:ff68f26e432648369a713849a9f93b58"
    }

    override var currentUserIsAnonymous: Bool {
        return mockIsAnonymous
    }

}
