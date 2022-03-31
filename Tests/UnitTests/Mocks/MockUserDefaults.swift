//
// Created by RevenueCat on 2/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

class MockUserDefaults: UserDefaults {

    var stringForKeyCalledValue: String?
    var setObjectForKeyCalledValue: String?
    var setObjectForKeyCallCount: Int = 0
    var removeObjectForKeyCalledValues: [String] = []
    var dataForKeyCalledValue: String?
    var objectForKeyCalledValue: String?
    var dictionaryForKeyCalledValue: String?
    var setBoolForKeyCalledValue: String?
    var setValueForKeyCalledValue: String?

    var mockValues: [String: Any] = [:]

    override func string(forKey defaultName: String) -> String? {
        stringForKeyCalledValue = defaultName
        return mockValues[defaultName] as? String
    }

    override func removeObject(forKey defaultName: String) {
        removeObjectForKeyCalledValues.append(defaultName)
        mockValues.removeValue(forKey: defaultName)
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        setObjectForKeyCallCount += 1
        setObjectForKeyCalledValue = defaultName
        mockValues[defaultName] = value
    }

    override func data(forKey defaultName: String) -> Data? {
        dataForKeyCalledValue = defaultName
        return mockValues[defaultName] as? Data
    }

    override func object(forKey defaultName: String) -> Any? {
        objectForKeyCalledValue = defaultName
        return mockValues[defaultName]
    }

    override func set(_ value: Bool, forKey defaultName: String) {
        setValueForKeyCalledValue = defaultName
        mockValues[defaultName] = value
    }

    override func dictionary(forKey defaultName: String) -> [String: Any]? {
        dictionaryForKeyCalledValue = defaultName
        return mockValues[defaultName] as? [String: Any]
    }

    override func dictionaryRepresentation() -> [String: Any] { mockValues }

    override func synchronize() -> Bool {
        // Nothing to do

        return false
    }

    override func removePersistentDomain(forName domainName: String) {
        mockValues = [:]
    }
}
