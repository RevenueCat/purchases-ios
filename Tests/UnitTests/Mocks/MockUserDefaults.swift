//
// Created by RevenueCat on 2/3/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

class MockUserDefaults: UserDefaults {

    private let lock = NSLock()

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
        return self.lock.perform {
            self.stringForKeyCalledValue = defaultName
            return self.mockValues[defaultName] as? String
        }
    }

    override func removeObject(forKey defaultName: String) {
        self.lock.perform {
            self.removeObjectForKeyCalledValues.append(defaultName)
            self.mockValues.removeValue(forKey: defaultName)
        }
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        self.lock.perform {
            self.setObjectForKeyCallCount += 1
            self.setObjectForKeyCalledValue = defaultName
            self.mockValues[defaultName] = value
        }
    }

    override func data(forKey defaultName: String) -> Data? {
        return self.lock.perform {
            self.dataForKeyCalledValue = defaultName
            return self.mockValues[defaultName] as? Data
        }
    }

    override func object(forKey defaultName: String) -> Any? {
        return self.lock.perform {
            self.objectForKeyCalledValue = defaultName
            return self.mockValues[defaultName]
        }
    }

    override func set(_ value: Bool, forKey defaultName: String) {
        self.lock.perform {
            self.setValueForKeyCalledValue = defaultName
            self.mockValues[defaultName] = value
        }
    }

    override func dictionary(forKey defaultName: String) -> [String: Any]? {
        return self.lock.perform {
            self.dictionaryForKeyCalledValue = defaultName
            return self.mockValues[defaultName] as? [String: Any]
        }
    }

    override func dictionaryRepresentation() -> [String: Any] {
        self.lock.perform { self.mockValues }
    }

    override func synchronize() -> Bool {
        // Nothing to do

        return false
    }

    override func removePersistentDomain(forName domainName: String) {
        self.lock.perform {
            self.mockValues = [:]
        }
    }
}

private extension NSLock {

    @discardableResult
    func perform<T>(_ block: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }

        return try block()
    }

}
