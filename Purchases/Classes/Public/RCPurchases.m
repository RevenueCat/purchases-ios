//
//  RCPurchases.m
//  Purchases
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchases.h"
#import "RCPurchases+Protected.h"

#import "RCStoreKitRequestFetcher.h"
#import "RCBackend.h"
#import "RCStoreKitWrapper.h"
#import "RCUtils.h"

@interface RCPurchases () <RCStoreKitWrapperDelegate>

@property (nonatomic) NSString *appUserID;

@property (nonatomic) RCStoreKitRequestFetcher *requestFetcher;
@property (nonatomic) RCBackend *backend;
@property (nonatomic) RCStoreKitWrapper *storeKitWrapper;
@property (nonatomic) NSNotificationCenter *notificationCenter;

@property (nonatomic) BOOL updatingPurchaserInfo;
@property (nonatomic) NSDate *purchaserInfoLastChecked;

@end

@implementation RCPurchases

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey appUserID:(NSString *)appUserID
{
    RCStoreKitRequestFetcher *fetcher = [[RCStoreKitRequestFetcher alloc] init];
    RCBackend *backend = [[RCBackend alloc] initWithAPIKey:APIKey];
    RCStoreKitWrapper *storeKitWrapper = [[RCStoreKitWrapper alloc] init];
    return [self initWithAppUserID:appUserID
                    requestFetcher:fetcher
                           backend:backend
                   storeKitWrapper:storeKitWrapper
                notificationCenter:[NSNotificationCenter defaultCenter]];
}
+ (NSString *)frameworkVersion {
    return @"0.3.0-SNAPSHOT";
}

- (instancetype _Nullable)initWithAppUserID:(NSString *)appUserID
                             requestFetcher:(RCStoreKitRequestFetcher *)requestFetcher
                                    backend:(RCBackend *)backend
                            storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
                         notificationCenter:(NSNotificationCenter *)notificationCenter
{
    if (self = [super init]) {
        self.appUserID = appUserID;

        self.requestFetcher = requestFetcher;
        self.backend = backend;
        self.storeKitWrapper = storeKitWrapper;
        self.storeKitWrapper.delegate = self;
        self.notificationCenter = notificationCenter;

        self.updatingPurchaserInfo = NO;
    }

    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

@synthesize delegate=_delegate;

- (void)setDelegate:(id<RCPurchasesDelegate>)delegate
{
    _delegate = delegate;

    if (delegate != nil) {
        self.storeKitWrapper.delegate = self;
        [self.notificationCenter addObserver:self
                                    selector:@selector(applicationDidBecomeActive:)
                                        name:UIApplicationDidBecomeActiveNotification object:nil];
        [self updatePurchaserInfo];
    } else {
        self.storeKitWrapper.delegate = nil;
        [self.notificationCenter removeObserver:self
                                           name:UIApplicationDidBecomeActiveNotification
                                         object:nil];
    }
}

- (id<RCPurchasesDelegate>)delegate
{
    return _delegate;
}

- (void)applicationDidBecomeActive:(__unused NSNotification *)notif
{
    [self updatePurchaserInfo];
}

- (void)updatePurchaserInfo
{
    NSTimeInterval timeSinceLastCheck = -[self.purchaserInfoLastChecked timeIntervalSinceNow];
    if (self.purchaserInfoLastChecked != nil && timeSinceLastCheck < 60.) return;

    self.purchaserInfoLastChecked = [NSDate date];

    [self.backend getSubscriberDataWithAppUserID:self.appUserID
                                      completion:^(RCPurchaserInfo * _Nullable info,
                                                   NSError * _Nullable error) {
        if (error == nil) {
            NSParameterAssert(self.delegate);
            [self.delegate purchases:self receivedUpdatedPurchaserInfo:info];
        } else {
            self.purchaserInfoLastChecked = nil;
        }
    }];
}

- (void)productsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers
                     completion:(void (^)(NSArray<SKProduct *>* products))completion
{
    [self.requestFetcher fetchProducts:productIdentifiers completion:^(NSArray<SKProduct *> * _Nonnull products) {
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

- (void)receiptData:(void (^ _Nonnull)(NSData * _Nonnull data))completion
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (receiptData == nil) {
        [self.requestFetcher fetchReceiptData:^{
            NSData *newReceiptData = [NSData dataWithContentsOfURL:receiptURL];
            completion(newReceiptData ?: [NSData data]);
        }];
    } else {
        completion(receiptData);
    }
}

- (void)handleReceiptPostWithTransaction:(SKPaymentTransaction *)transaction
                           purchaserInfo:(RCPurchaserInfo * _Nullable)info
                                   error:(NSError * _Nullable)error
{
    NSParameterAssert(self.delegate);
    if (info) {
        [self.delegate purchases:self
            completedTransaction:transaction
                 withUpdatedInfo:info];
        [self.storeKitWrapper finishTransaction:transaction];
    } else if (error.code == RCFinishableError) {
        [self.delegate purchases:self failedTransaction:transaction withReason:error];
        [self.storeKitWrapper finishTransaction:transaction];
    } else if (error.code == RCUnfinishableError) {
        [self.delegate purchases:self failedTransaction:transaction withReason:error];
    } else {
        RCLog(@"Unexpected error from backend");
        [self.delegate purchases:self failedTransaction:transaction withReason:error];
    }
}

/*
 RCStoreKitWrapperDelegate
 */

- (void)storeKitWrapper:(RCStoreKitWrapper *)storeKitWrapper
     updatedTransaction:(SKPaymentTransaction *)transaction
{
    switch (transaction.transactionState) {
        case SKPaymentTransactionStatePurchased: {
            [self receiptData:^(NSData * _Nonnull data) {
                [self.backend postReceiptData:data
                                    appUserID:self.appUserID
                                   completion:^(RCPurchaserInfo * _Nullable info,
                                                NSError * _Nullable error) {
                                       [self handleReceiptPostWithTransaction:transaction
                                                                purchaserInfo:info
                                                                        error:error];
                                   }];
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
