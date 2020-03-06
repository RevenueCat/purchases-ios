//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockUserManager: RCIdentityManager {

    var configurationCalled = false
    var identifyError: Error?
    var aliasError: Error?
    var aliasCalled = false
    var identifyCalled = false
    var resetCalled = false
    var mockIsAnonymous = false
    var mockAppUserID: String

    init(mockAppUserID: String) {
        self.mockAppUserID = mockAppUserID
        super.init()
    }

    override var currentAppUserID: String {
        if (mockIsAnonymous) {
            return "$RCAnonymousID:ff68f26e432648369a713849a9f93b58"
        } else {
            return mockAppUserID
        }
    }

    override func configure(withAppUserID appUserID: String?) {
        configurationCalled = true
    }

    override func createAlias(_ alias: String, withCompletionBlock completion: @escaping (Error?) -> ()) {
        aliasCalled = true
        if (aliasError != nil) {
            completion(aliasError)
        } else {
            mockAppUserID = alias
            completion(nil)
        }
    }

    override func identifyAppUserID(_ appUserID: String, withCompletionBlock completion: @escaping (Error?) -> ()) {
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
