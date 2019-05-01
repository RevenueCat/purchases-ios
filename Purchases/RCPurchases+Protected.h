//
//  RCPurchases+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 10/2/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//


@class RCPurchases, RCStoreKitRequestFetcher, RCBackend, RCStoreKitWrapper, RCReceiptFetcher;

NS_ASSUME_NONNULL_BEGIN

@interface RCPurchases (Protected)

- (instancetype _Nullable)initWithAppUserID:(NSString * _Nullable)appUserID
                             requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                             receiptFetcher:(RCReceiptFetcher *)receiptFetcher
                                    backend:(RCBackend *)backend
                            storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
                         notificationCenter:(NSNotificationCenter *)notificationCenter
                               userDefaults:(NSUserDefaults *)userDefaults
                               observerMode:(Boolean)observerMode;

@end

NS_ASSUME_NONNULL_END
