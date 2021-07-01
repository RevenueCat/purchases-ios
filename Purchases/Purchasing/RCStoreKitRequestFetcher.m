//
//  RCStoreKitRequestFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RCStoreKitRequestFetcher.h"
#import "RCLogUtils.h"
@import PurchasesCoreSwift;

@implementation RCReceiptRefreshRequestFactory : NSObject

- (SKReceiptRefreshRequest *)receiptRefreshRequest
{
    return [[SKReceiptRefreshRequest alloc] init];
}

@end

@interface RCStoreKitRequestFetcher () <SKRequestDelegate>
@property (nonatomic) RCReceiptRefreshRequestFactory *requestFactory;

@property (nonatomic) SKRequest *receiptRefreshRequest;
@property (nonatomic) NSMutableArray<RCFetchReceiptCompletionHandler> *receiptRefreshCompletionHandlers;

@end

@implementation RCStoreKitRequestFetcher

- (nullable instancetype)init {
    return [self initWithRequestFactory:[RCReceiptRefreshRequestFactory new]];
}

- (nullable instancetype)initWithRequestFactory:(RCReceiptRefreshRequestFactory *)requestFactory;
{
    if (self = [super init]) {
        self.requestFactory = requestFactory;
        self.receiptRefreshRequest = nil;
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
    }
    return self;
}

- (void)fetchReceiptData:(void (^ _Nonnull)(void))completion
{
    @synchronized(self) {
        [self.receiptRefreshCompletionHandlers addObject:[completion copy]];
        
        if (self.receiptRefreshRequest == nil) {
            self.receiptRefreshRequest = [self.requestFactory receiptRefreshRequest];
            self.receiptRefreshRequest.delegate = self;
            [self.receiptRefreshRequest start];
        }
    }
}

- (NSArray<RCFetchReceiptCompletionHandler> *)finishReceiptRequest:(SKRequest *)request
{
    @synchronized(self) {
        self.receiptRefreshRequest = nil;
        NSArray *handlers = [NSArray arrayWithArray:self.receiptRefreshCompletionHandlers];
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
        return handlers;
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    if ([request isKindOfClass:SKReceiptRefreshRequest.class]) {
        NSArray<RCFetchReceiptCompletionHandler> *receiptHandlers = [self finishReceiptRequest:request];
        for (RCFetchReceiptCompletionHandler receiptHandler in receiptHandlers) {
            receiptHandler();
        }
    }
    [request cancel];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    RCAppleErrorLog(RCStrings.offering.sk_request_failed, error.localizedDescription);
    if ([request isKindOfClass:SKReceiptRefreshRequest.class]) {
        NSArray<RCFetchReceiptCompletionHandler> *receiptHandlers = [self finishReceiptRequest:request];
        for (RCFetchReceiptCompletionHandler receiptHandler in receiptHandlers) {
            receiptHandler();
        }
    }
    [request cancel];
}

@end
