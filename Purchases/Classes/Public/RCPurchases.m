//
//  RCPurchases.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"

#import "RCProductFetcher.h"
#import "RCBackend.h"
#import "RCStoreKitWrapper.h"
#import "RCUtils.h"

@interface RCPurchases () <RCStoreKitWrapperDelegate>

@property (nonatomic) NSString *appUserID;

@property (nonatomic) RCProductFetcher *productFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;

@end

@implementation RCPurchases

- (instancetype _Nullable)initWithAPIKey:(NSString * _Nonnull)APIKey appUserID:(NSString *)appUserID
{
    RCProductFetcher *fetcher = [[RCProductFetcher alloc] init];
    RCBackend *backend = [[RCBackend alloc] initWithAPIKey:APIKey];
    RCStoreKitWrapper *storeKitWrapper = [[RCStoreKitWrapper alloc] init];
    return [self initWithAppUserID:appUserID
                       productFetcher:fetcher
                              backend:backend
                      storeKitWrapper:storeKitWrapper];
}
+ (NSString *)frameworkVersion {
    return @"0.2.0-SNAPSHOT";
}

- (instancetype _Nullable)initWithAppUserID:(NSString *)appUserID
                          productFetcher:(RCProductFetcher *)productFetcher
                                 backend:(RCBackend *)backend
                         storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
{
    if (self = [super init])
    {
        self.appUserID = appUserID;

        self.productFetcher = productFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;
        self.storeKitWrapper.delegate = self;

        [self.storeKitWrapper addObserver:self forKeyPath:@"purchasing" options:0 context:NULL];
        [self.backend addObserver:self forKeyPath:@"purchasing" options:0 context:NULL];
    }

    return self;
}

- (void)dealloc
{
    [self.storeKitWrapper removeObserver:self forKeyPath:@"purchasing"];
    [self.backend removeObserver:self forKeyPath:@"purchasing"];
}

@synthesize delegate=_delegate;

- (void)setDelegate:(id<RCPurchasesDelegate>)delegate
{
    _delegate = delegate;

    if (delegate != nil) {
        self.storeKitWrapper.delegate = self;
    } else {
        self.storeKitWrapper.delegate = nil;
    }
}

- (id<RCPurchasesDelegate>)delegate
{
    return _delegate;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"purchasing"]) {
        [self willChangeValueForKey:@"purchasing"];
        [self didChangeValueForKey:@"purchasing"];
    }
}

- (void)productsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers
                     completion:(void (^)(NSArray<SKProduct *>* products))completion
{
    [self.productFetcher fetchProducts:productIdentifiers completion:^(NSArray<SKProduct *> * _Nonnull products) {
        completion(products);
    }];
}

- (void)purchaserInfoWithCompletion:(void (^)(RCPurchaserInfo * _Nullable purchaserInfo))completion
{
    [self.backend getSubscriberDataWithAppUserID:self.appUserID completion:^(RCPurchaserInfo * _Nullable purchaserInfo, NSError * _Nullable error) {

        if (error) {
            RCLog(@"Error fetching purchaser info: %@", error.localizedDescription);
        }

        completion(purchaserInfo);
    }];
}

- (void)makePurchase:(SKProduct *)product
{
    [self makePurchase:product quantity:1];
}

- (void)makePurchase:(SKProduct *)product
            quantity:(NSInteger)quantity
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = quantity;
    payment.applicationUsername = self.appUserID;

    [self.storeKitWrapper addPayment:payment];
}

- (BOOL)purchasing {
    return (self.storeKitWrapper.purchasing || self.backend.purchasing);
}

/*
 RCStoreKitWrapperDelegate
 */

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     updatedTransaction:(SKPaymentTransaction *)transaction
{
    switch (transaction.transactionState) {
        case SKPaymentTransactionStatePurchased: {
            [self.backend postReceiptData:self.storeKitWrapper.receiptData
                                appUserID:self.appUserID
                               completion:^(RCPurchaserInfo * _Nullable info, NSError * _Nullable error) {
                                   NSParameterAssert(self.delegate);
                                   if (info) {
                                       [self.delegate purchases:self
                                           completedTransaction:transaction
                                                withUpdatedInfo:info];
                                       [self.storeKitWrapper finishTransaction:transaction];
                                   } else if (error) {
                                       [self.delegate purchases:self failedTransaction:transaction withReason:error];
                                   } else {
                                       RCLog(@"Unexpected error from backend");
                                   }
                               }];
            break;
        }
        case SKPaymentTransactionStateFailed: {
            [self.delegate purchases:self failedTransaction:transaction withReason:transaction.error];
            [self.storeKitWrapper finishTransaction:transaction];
            break;
        }
        case SKPaymentTransactionStateDeferred:
        case SKPaymentTransactionStatePurchasing:
        case SKPaymentTransactionStateRestored:
            break;
    }    
}

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     removedTransaction:(SKPaymentTransaction *)transaction
{

}


@end
