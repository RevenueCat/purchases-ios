//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
import Foundation

class MockNotificationCenter: NotificationCenter {

    typealias AddObserverTuple = (observer: AnyObject,
                                  selector: Selector,
                                  notificationName: NSNotification.Name?,
                                  object: Any?)
    var observers = [AddObserverTuple]()

    override func addObserver(
        _ observer: Any,
        selector aSelector: Selector,
        name aName: NSNotification.Name?,
        object anObject: Any?
    ) {
        observers.append((observer as AnyObject, aSelector, aName, anObject))
    }

    override func removeObserver(_ anObserver: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        observers = observers.filter {
            $0.0 !== anObserver as AnyObject || $0.2 != aName
        }
    }

    func fireNotifications() {
        for (observer, selector, name, object) in observers {
            var notification: NSNotification?
            if let name = name {
                notification = NSNotification(name: name, object: object)
            }
            _ = observer.perform(selector, with: notification)
        }
    }
}
