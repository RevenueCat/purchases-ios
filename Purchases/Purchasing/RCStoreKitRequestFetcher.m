//
//  RCProductFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RCStoreKitRequestFetcher.h"
#import "RCLogUtils.h"
@import PurchasesCoreSwift;

@implementation RCProductsRequestFactory : NSObject

- (SKProductsRequest *)requestForProductIdentifiers:(NSSet<NSString *> *)identifiers
{
    return [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
}

- (SKReceiptRefreshRequest *)receiptRefreshRequest
{
    return [[SKReceiptRefreshRequest alloc] init];
}

@end

@interface RCStoreKitRequestFetcher ()

@property (nonatomic) RCProductsRequestFactory *requestFactory;
@property (nonatomic) RCOperationDispatcher *operationDispatcher;

@property (nonatomic) NSMutableDictionary<NSSet *, SKProductsRequest *> *productsRequests;
@property (nonatomic) NSMutableDictionary<NSSet *, NSMutableArray<RCFetchProductsCompletionHandler> *> *productsCompletionHandlers;

@property (nonatomic) SKRequest *receiptRefreshRequest;
@property (nonatomic) NSMutableArray<RCFetchReceiptCompletionHandler> *receiptRefreshCompletionHandlers;

@end

@implementation RCStoreKitRequestFetcher

- (nullable instancetype)initWithOperationDispatcher:(RCOperationDispatcher *)operationDispatcher {
    return [self initWithRequestFactory:[[RCProductsRequestFactory alloc] init]
                    operationDispatcher:operationDispatcher];
}

- (nullable instancetype)initWithRequestFactory:(RCProductsRequestFactory *)requestFactory
                            operationDispatcher:(RCOperationDispatcher *)operationDispatcher {
    if (self = [super init]) {
        self.requestFactory = requestFactory;
        self.operationDispatcher = operationDispatcher;

        self.productsRequests = [NSMutableDictionary new];
        self.productsCompletionHandlers = [NSMutableDictionary new];
        
        self.receiptRefreshRequest = nil;
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
        self.requestTimeoutInSeconds = 30;
    }
    return self;
}

- (void)fetchProducts:(NSSet<NSString *> *)identifiers
           completion:(RCFetchProductsCompletionHandler)completion {
    
    @synchronized(self) {
        SKProductsRequest *newRequest = nil;
        
        if (self.productsRequests[identifiers] == nil) {
            RCDebugLog(RCStrings.offering.fetching_products, identifiers);
            newRequest = [self.requestFactory requestForProductIdentifiers:identifiers];
            newRequest.delegate = self;
            
            self.productsRequests[identifiers] = newRequest;
            self.productsCompletionHandlers[identifiers] = [NSMutableArray new];
        }
        
        NSMutableArray *handlers = self.productsCompletionHandlers[identifiers];
        NSAssert(handlers != nil, @"Corrupted handler storage");
        
        [handlers addObject:completion];

        [newRequest start];
        [self scheduleCancellationInCaseOfTimeoutForProductIdentifiers:identifiers];
    }
    
    NSAssert(self.productsRequests.count == self.productsCompletionHandlers.count, @"Corrupted handler storage");
}

- (void)fetchReceiptData:(void (^ _Nonnull)(void))completion {
    @synchronized(self) {
        [self.receiptRefreshCompletionHandlers addObject:[completion copy]];
        
        if (self.receiptRefreshRequest == nil) {
            self.receiptRefreshRequest = [self.requestFactory receiptRefreshRequest];
            self.receiptRefreshRequest.delegate = self;
            [self.receiptRefreshRequest start];
        }
    }
}

- (NSArray<RCFetchProductsCompletionHandler> *)finishProductsRequest:(SKRequest *)request {
    NSMutableArray<RCFetchProductsCompletionHandler> *handlers;
    @synchronized(self) {
        NSSet *associatedProductIdentifiers = nil;
        for (NSSet *productIdentifiers in self.productsRequests) {
            SKRequest *r = self.productsRequests[productIdentifiers];
            if (r == request) {
                NSAssert(associatedProductIdentifiers == nil, @"Request maps to multiple product sets");
                associatedProductIdentifiers = productIdentifiers;
            }
        }
        if (associatedProductIdentifiers == nil) {
            return @[];
        }
        
        handlers = self.productsCompletionHandlers[associatedProductIdentifiers];
        [self.productsRequests removeObjectForKey:associatedProductIdentifiers];
        [self.productsCompletionHandlers removeObjectForKey:associatedProductIdentifiers];
    }
    NSAssert(self.productsRequests.count == self.productsCompletionHandlers.count, @"Corrupted handler storage");
    return handlers;
}

- (NSArray<RCFetchReceiptCompletionHandler> *)finishReceiptRequest:(SKRequest *)request {
    @synchronized(self) {
        self.receiptRefreshRequest = nil;
        NSArray *handlers = [NSArray arrayWithArray:self.receiptRefreshCompletionHandlers];
        self.receiptRefreshCompletionHandlers = [NSMutableArray new];
        return handlers;
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    if ([request isKindOfClass:SKReceiptRefreshRequest.class]) {
        NSArray<RCFetchReceiptCompletionHandler> *receiptHandlers = [self finishReceiptRequest:request];
        for (RCFetchReceiptCompletionHandler receiptHandler in receiptHandlers) {
            receiptHandler();
        }
    }
    [request cancel];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    RCAppleErrorLog(RCStrings.offering.fetching_products_failed, error.localizedDescription);
    if ([request isKindOfClass:SKReceiptRefreshRequest.class]) {
        NSArray<RCFetchReceiptCompletionHandler> *receiptHandlers = [self finishReceiptRequest:request];
        for (RCFetchReceiptCompletionHandler receiptHandler in receiptHandlers) {
            receiptHandler();
        }
    } else if ([request isKindOfClass:SKProductsRequest.class]) {
        NSArray<RCFetchProductsCompletionHandler> *productsHandlers = [self finishProductsRequest:request];
        for (RCFetchProductsCompletionHandler handler in productsHandlers) {
            handler(@[]);
        }
    }
    [request cancel];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    RCDebugLog(@"%@", RCStrings.offering.fetching_products_finished);
    RCPurchaseLog(@"%@", RCStrings.offering.retrieved_products);
    for (SKProduct *p in response.products) {
        RCPurchaseLog(RCStrings.offering.list_products, p.productIdentifier, p);
    }
    if (response.invalidProductIdentifiers.count > 0) {
        RCAppleWarningLog(RCStrings.offering.invalid_product_identifiers, response.invalidProductIdentifiers);        
    }

    NSArray<RCFetchProductsCompletionHandler> *handlers = [self finishProductsRequest:request];
    RCDebugLog(RCStrings.offering.completion_handlers_waiting_on_products, (unsigned long)handlers.count);
    for (RCFetchProductsCompletionHandler handler in handlers) {
        handler(response.products);
    }
}

- (void)scheduleCancellationInCaseOfTimeoutForProductIdentifiers:(NSSet<NSString *> *)identifiers {
    [self.operationDispatcher dispatchOnWorkerThreadAfterDelayInSeconds:self.requestTimeoutInSeconds
                                                                  block: ^{
        @synchronized (self) {
            SKProductsRequest * _Nullable maybeRequest = [self.productsRequests objectForKey:identifiers];
            if (maybeRequest == nil) {
                return;
            }
            RCAppleErrorLog(RCStrings.offering.skproductsrequest_timed_out, self.requestTimeoutInSeconds);

            SKProductsRequest *request = maybeRequest;
            [request cancel];
            NSArray<RCFetchProductsCompletionHandler> *productsHandlers = [self finishProductsRequest:request];
            for (RCFetchProductsCompletionHandler handler in productsHandlers) {
                handler(@[]);
            }
        }
    }];

}

@end
