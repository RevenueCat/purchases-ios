//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoManager+Combine.swift
//
//  Created by Nacho Soto on 1/30/22.

#if canImport(Combine)

import Combine

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension CustomerInfoManager {

    var customerInfoPublisher: CustomerInfoPublisher {
        return CustomerInfoPublisher(manager: self)
    }

}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
private final class CustomerInfoSubscription<SubscriberType: Subscriber>: Subscription
where SubscriberType.Input == CustomerInfo {

    private var subscriber: SubscriberType?
    private let manager: CustomerInfoManager
    private let disposable: () -> Void

    init(subscriber: SubscriberType, manager: CustomerInfoManager) {
        self.subscriber = subscriber
        self.manager = manager

        self.disposable = manager.monitorChanges {
            Self.send($0, subscriber)
        }
    }

    func request(_ demand: Subscribers.Demand) {
        if demand != .none,
           let subscriber = self.subscriber, let lastSentCustomerInfo = self.manager.lastSentCustomerInfo {
            Self.send(lastSentCustomerInfo, subscriber)
        }
    }

    func cancel() {
        self.subscriber = nil
        self.disposable()
    }

    private static func send(_ customerInfo: CustomerInfo, _ subscriber: SubscriberType) {
        _ = subscriber.receive(customerInfo)
    }

}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct CustomerInfoPublisher: Publisher {

    typealias Output = CustomerInfo
    typealias Failure = Never

    private let manager: CustomerInfoManager

    init(manager: CustomerInfoManager) {
        self.manager = manager
    }

    func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Self.Failure, S.Input == Self.Output {
        let subscription = CustomerInfoSubscription(subscriber: subscriber, manager: manager)
        subscriber.receive(subscription: subscription)
    }

}

#endif
