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
@property (class, nonatomic, assign) BOOL simulatesAskToBuyInSandbox API_AVAILABLE(ios(8.0), macos(10.14), watchos(6.2), macCatalyst(13.0), tvos(9.0));

@property (nonatomic, readonly, nullable) SKStorefront *currentStorefront API_AVAILABLE(ios(13.0), macos(10.15), watchos(6.2), macCatalyst(13.1), tvos(13.0));

- (void)addPayment:(SKPayment *)payment;
- (void)finishTransaction:(SKPaymentTransaction *)transaction;
- (void)presentCodeRedemptionSheet API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(tvos, macos, watchos);

- (SKMutablePayment *)paymentWithProduct:(SKProduct *)product;
- (SKMutablePayment *)paymentWithProduct:(SKProduct *)product discount:(SKPaymentDiscount *)discount API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2), macCatalyst(13.0), tvos(12.2));

/**
 * Returns the country code for the current `SKStoreFront`, or `nil` if not available.
 */
- (nullable NSString *)countryCode;

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
