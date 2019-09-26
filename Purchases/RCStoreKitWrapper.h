//
//  RCStoreKitWrapper.h
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RCStoreKitWrapperDelegate;

@interface RCStoreKitWrapper : NSObject <SKPaymentTransactionObserver>

- (nullable instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue;

@property (nonatomic, weak, nullable) id<RCStoreKitWrapperDelegate> delegate;

- (void)addPayment:(SKPayment *)payment;
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

@end

@protocol RCStoreKitWrapperDelegate

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     updatedTransaction:(SKPaymentTransaction *)transaction;

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     removedTransaction:(SKPaymentTransaction *)transaction;

- (BOOL)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
  shouldAddStorePayment:(SKPayment *)payment
             forProduct:(SKProduct *)product;

@end

NS_ASSUME_NONNULL_END
