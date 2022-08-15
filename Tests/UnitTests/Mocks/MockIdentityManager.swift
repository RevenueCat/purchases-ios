//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockIdentityManager: IdentityManager {

    var identifyError: Error?
    var identifyCalled = false
    var resetCalled = false
    var mockIsAnonymous = false
    var mockAppUserID: String

    let mockAttributeSyncing = MockAttributeSyncing()

    init(mockAppUserID: String) {
        // swiftlint:disable:next force_try
        let mockSystemInfo = try! MockSystemInfo(platformInfo: nil,
                                                 finishTransactions: false,
                                                 dangerousSettings: nil)
        let mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: mockSystemInfo)
        let mockBackend = MockBackend()

        self.mockAppUserID = mockAppUserID

        super.init(deviceCache: mockDeviceCache,
                   backend: mockBackend,
                   customerInfoManager: MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                                deviceCache: mockDeviceCache,
                                                                backend: mockBackend,
                                                                systemInfo: mockSystemInfo),
                   attributeSyncing: self.mockAttributeSyncing,
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

    // MARK: - LogIn

    var mockLogInResult: IdentityAPI.LogInResponse!
    var invokedLogIn = false
    var invokedLogInCount = 0
    var invokedLogInParametersList: [String] = []

    override func logIn(appUserID: String, completion: @escaping IdentityAPI.LogInResponseHandler) {
        self.invokedLogIn = true
        self.invokedLogInCount += 1
        self.invokedLogInParametersList.append(appUserID)

        completion(self.mockLogInResult)
    }

    // MARK: - LogOut

    var mockLogOutError: BackendError?
    var invokedLogOut = false
    var invokedLogOutCount = 0

    override func logOut(completion: @escaping (Error?) -> Void) {
        self.invokedLogOut = true
        self.invokedLogOutCount += 1

        completion(self.mockLogOutError)
    }

}
