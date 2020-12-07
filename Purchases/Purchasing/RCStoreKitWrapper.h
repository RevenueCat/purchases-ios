//
//  RCStoreKitWrapper.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
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
- (void)presentCodeRedemptionSheet API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(tvos, macos, watchos);

@end

@protocol RCStoreKitWrapperDelegate

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     updatedTransaction:(SKPaymentTransaction *)transaction;

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     removedTransaction:(SKPaymentTransaction *)transaction;

- (BOOL)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
  shouldAddStorePayment:(SKPayment *)payment
             forProduct:(SKProduct *)product;

- (void)                   storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
didRevokeEntitlementsForProductIdentifiers:(NSArray<NSString *> *)productIdentifiers
API_AVAILABLE(ios(14.0), macos(11.0), tvos(14.0), watchos(7.0));

@end

NS_ASSUME_NONNULL_END
