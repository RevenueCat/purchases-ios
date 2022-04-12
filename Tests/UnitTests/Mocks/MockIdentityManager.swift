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
        // swiftlint:disable:next force_try
        let mockSystemInfo = try! MockSystemInfo(platformInfo: nil,
                                                 finishTransactions: false,
                                                 dangerousSettings: nil)
        let mockDeviceCache = MockDeviceCache(systemInfo: mockSystemInfo)
        let mockBackend = MockBackend()

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
        if mockIsAnonymous {
            return "$RCAnonymousID:ff68f26e432648369a713849a9f93b58"
        } else {
            return mockAppUserID
        }
    }

    override var currentUserIsAnonymous: Bool {
        return mockIsAnonymous
    }

    override func logIn(appUserID: String, completion: @escaping Backend.LogInResponseHandler) {
        fatalError("Logging in not supported on mock")
    }

    override func logOut(completion: (Error?) -> Void) {
        fatalError("Logging out not supported on mock")
    }

}
