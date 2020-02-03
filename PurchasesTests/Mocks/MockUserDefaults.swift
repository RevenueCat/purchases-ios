//
// Created by RevenueCat on 2/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

class MockUserDefaults: UserDefaults {

    var stringForKeyCalledValue: String? = nil
    var setObjectForKeyCalledValue: String? = nil
    var removeObjectForKeyCalledValues: Array<String> = []
    var dataForKeyCalledValue: String? = nil
    var objectForKeyCalledValue: String? = nil
    var setBoolForKeyCalledValue: String? = nil
    var setValueForKeyCalledValue: String? = nil

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
}