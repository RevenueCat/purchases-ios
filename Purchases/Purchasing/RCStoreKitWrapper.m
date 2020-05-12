//
//  RCStoreKitWrapper.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCStoreKitWrapper.h"
#import "RCCrossPlatformSupport.h"

#import "RCLogUtils.h"

@interface RCStoreKitWrapper ()
@property (nonatomic) SKPaymentQueue *paymentQueue;
@end

@implementation RCStoreKitWrapper

@synthesize delegate = _delegate;

- (instancetype)init
{
    return [self initWithPaymentQueue:SKPaymentQueue.defaultQueue];
}

- (nullable instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue
{
    if (self = [super init]) {
        self.paymentQueue = paymentQueue;
    }
    return self;
}

- (void)dealloc
{
    [self.paymentQueue removeTransactionObserver:self];
}

- (void)setDelegate:(id<RCStoreKitWrapperDelegate>)delegate
{
    _delegate = delegate;

    if (_delegate != nil) {
        [self.paymentQueue addTransactionObserver:self];
    } else {
        [self.paymentQueue removeTransactionObserver:self];
    }
}

- (id<RCStoreKitWrapperDelegate>)delegate
{
    return _delegate;
}

- (void)addPayment:(SKPayment *)payment
{
    [self.paymentQueue addPayment:payment];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction
{
    RCDebugLog(@"Finishing %@ %@ (%@)", transaction.payment.productIdentifier,
                transaction.transactionIdentifier, transaction.originalTransaction.transactionIdentifier);

    [self.paymentQueue finishTransaction:transaction];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        RCDebugLog(@"PaymentQueue updatedTransaction: %@ %@ (%@) %@ - %d", transaction.payment.productIdentifier, transaction.transactionIdentifier, transaction.error, transaction.originalTransaction.transactionIdentifier, transaction.transactionState);
        [self.delegate storeKitWrapper:self updatedTransaction:transaction];
    }
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        RCDebugLog(@"PaymentQueue removedTransaction: %@ %@ (%@ %@) %@ - %d", transaction.payment.productIdentifier, transaction.transactionIdentifier, transaction.originalTransaction.transactionIdentifier, transaction.error, transaction.error.userInfo, transaction.transactionState);
        [self.delegate storeKitWrapper:self removedTransaction:transaction];
    }
}

#if PURCHASES_INITIATED_FROM_APP_STORE_AVAILABLE
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product
{
    return [self.delegate storeKitWrapper:self shouldAddStorePayment:payment forProduct:product];
}
#endif

@end
