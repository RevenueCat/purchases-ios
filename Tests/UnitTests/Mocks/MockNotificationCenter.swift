//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
import Foundation

@testable import RevenueCat

class MockNotificationCenter: NotificationCenter {

    typealias ObserversWithSelector = (observer: WeakBox<AnyObject>,
                                       selector: Selector,
                                       notificationName: NSNotification.Name?,
                                       object: Any?)
    var observers = [ObserversWithSelector]()

    override func addObserver(
        _ observer: Any,
        selector aSelector: Selector,
        name aName: NSNotification.Name?,
        object anObject: Any?
    ) {
        self.observers.append((.init(observer as AnyObject), aSelector, aName, anObject))
    }

    typealias ObserversWithBlock = (block: (Notification) -> Void,
                                    notificationName: NSNotification.Name?,
                                    object: Any?)
    var observersWithBlock = [ObserversWithBlock]()

    override func addObserver(
        forName name: NSNotification.Name?,
        object: Any?,
        queue: OperationQueue?,
        using block: @escaping (Notification) -> Void
    ) -> NSObjectProtocol {
        self.observersWithBlock.append((block, name, object))

        return NSObject()
    }

    override func removeObserver(_ anObserver: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        self.observers = self.observers.filter {
            $0.0.value !== anObserver as AnyObject || $0.2 != aName
        }
    }

    func fireNotifications() {
        for (observer, selector, name, object) in self.observers {
            var notification: NSNotification?
            if let name = name {
                notification = NSNotification(name: name, object: object)
            }
            _ = observer.value?.perform(selector, with: notification)
        }

        for (block, name, object) in self.observersWithBlock {
            if let name = name {
                block(Notification(name: name, object: object))
            }
        }
    }

    func fireApplicationDidEnterBackgroundNotification() {
        fireNotification(SystemInfo.applicationDidEnterBackgroundNotification)
    }

    func fireApplicationWillEnterForegroundNotification() {
        fireNotification(SystemInfo.applicationWillEnterForegroundNotification)
    }

    private func fireNotification(_ notificationName: NSNotification.Name) {
        for (observer, selector, name, object) in self.observers {
            var notification: NSNotification?
            if let name = name, name == notificationName {
                notification = NSNotification(name: name, object: object)
                _ = observer.value?.perform(selector, with: notification)
            }
        }

        for (block, name, object) in self.observersWithBlock {
            if let name = name, name == notificationName {
                block(Notification(name: name, object: object))
            }
        }
    }
}

extension MockNotificationCenter: @unchecked Sendable {}
