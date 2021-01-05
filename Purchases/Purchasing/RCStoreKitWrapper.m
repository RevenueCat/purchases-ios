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
@import PurchasesCoreSwift;

@interface RCStoreKitWrapper ()
@property (nonatomic) SKPaymentQueue *paymentQueue;
@end

@implementation RCStoreKitWrapper

static BOOL _simulatesAskToBuyInSandbox = NO;
@synthesize delegate = _delegate;

- (instancetype)init {
    return [self initWithPaymentQueue:SKPaymentQueue.defaultQueue];
}

- (nullable instancetype)initWithPaymentQueue:(SKPaymentQueue *)paymentQueue {
    if (self = [super init]) {
        self.paymentQueue = paymentQueue;
    }
    return self;
}

- (void)dealloc {
    [self.paymentQueue removeTransactionObserver:self];
}

- (void)setDelegate:(id<RCStoreKitWrapperDelegate>)delegate {
    _delegate = delegate;

    if (_delegate != nil) {
        [self.paymentQueue addTransactionObserver:self];
    } else {
        [self.paymentQueue removeTransactionObserver:self];
    }
}

+ (BOOL)simulatesAskToBuyInSandbox {
    return _simulatesAskToBuyInSandbox;
}

+ (void)setSimulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox {
    _simulatesAskToBuyInSandbox = simulatesAskToBuyInSandbox;
}

- (id<RCStoreKitWrapperDelegate>)delegate {
    return _delegate;
}

- (void)addPayment:(SKPayment *)payment {
    [self.paymentQueue addPayment:payment];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    RCPurchaseLog(RCStrings.purchase.finishing_transaction,
                  transaction.payment.productIdentifier,
                  transaction.transactionIdentifier,
                  transaction.originalTransaction.transactionIdentifier);

    [self.paymentQueue finishTransaction:transaction];
}

- (void)presentCodeRedemptionSheet API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(tvos, macos, watchos) {
#ifdef __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        [self.paymentQueue presentCodeRedemptionSheet];
    } else {
        RCLog(@"%@", RCStrings.purchase.presenting_code_redemption_sheet_unavailable);
    }
#endif
}

- (SKMutablePayment *)paymentWithProduct:(SKProduct *)product {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    if (@available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, tvos 9.0, *)) {
        payment.simulatesAskToBuyInSandbox = self.class.simulatesAskToBuyInSandbox;
    }
    return payment;
}

- (SKMutablePayment *)paymentWithProduct:(SKProduct *)product discount:(SKPaymentDiscount *)discount {
    SKMutablePayment *payment = [self paymentWithProduct:product];
    payment.paymentDiscount = discount;
    return payment;
}

#pragma MARK: SKPaymentQueueDelegate

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        RCDebugLog(RCStrings.purchase.paymentqueue_updatedtransaction,
                   transaction.payment.productIdentifier,
                   transaction.transactionIdentifier,
                   transaction.error,
                   transaction.originalTransaction.transactionIdentifier,
                   (long)transaction.transactionState);
        [self.delegate storeKitWrapper:self updatedTransaction:transaction];
    }
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue
 removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        RCDebugLog(RCStrings.purchase.paymentqueue_removedtransaction,
                   transaction.payment.productIdentifier,
                   transaction.transactionIdentifier,
                   transaction.originalTransaction.transactionIdentifier,
                   transaction.error,
                   transaction.error.userInfo,
                   (long)transaction.transactionState);
        [self.delegate storeKitWrapper:self removedTransaction:transaction];
    }
}

#if PURCHASES_INITIATED_FROM_APP_STORE_AVAILABLE
- (BOOL) paymentQueue:(SKPaymentQueue *)queue
shouldAddStorePayment:(SKPayment *)payment
           forProduct:(SKProduct *)product {
    return [self.delegate storeKitWrapper:self shouldAddStorePayment:payment forProduct:product];
}
#endif

// Sent when access to a family shared subscription is revoked from a family member or canceled the subscription
- (void)                      paymentQueue:(SKPaymentQueue *)queue
didRevokeEntitlementsForProductIdentifiers:(NSArray<NSString *> *)productIdentifiers
API_AVAILABLE(ios(14.0), macos(11.0), tvos(14.0), watchos(7.0)) {
    RCDebugLog(RCStrings.purchase.paymentqueue_revoked_entitlements_for_product_identifiers, productIdentifiers);
    [self.delegate storeKitWrapper:self didRevokeEntitlementsForProductIdentifiers:productIdentifiers];
}

@end
