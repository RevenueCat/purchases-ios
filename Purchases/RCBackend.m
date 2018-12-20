//
//  RCBackend.m
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import "RCBackend.h"

#import "RCHTTPClient.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCIntroEligibility.h"
#import "RCIntroEligibility+Protected.h"
#import "RCEntitlement+Protected.h"
#import "RCOffering+Protected.h"

NSErrorDomain const RCBackendErrorDomain = @"RCBackendErrorDomain";

API_AVAILABLE(ios(11.2), macos(10.13.2))
RCPaymentMode RCPaymentModeFromSKProductDiscountPaymentMode(SKProductDiscountPaymentMode paymentMode)
{
    switch (paymentMode) {
        case SKProductDiscountPaymentModePayUpFront:
            return RCPaymentModePayUpFront;
        case SKProductDiscountPaymentModePayAsYouGo:
            return RCPaymentModePayAsYouGo;
        case SKProductDiscountPaymentModeFreeTrial:
            return RCPaymentModeFreeTrial;
        default:
            return RCPaymentModeNone;
    }
}

@interface RCBackend ()

@property (nonatomic) RCHTTPClient *httpClient;
@property (nonatomic) NSString *APIKey;

@property (nonatomic) NSMutableDictionary<NSString *, NSMutableArray *> *receiptCallbacksCache;

@end

@implementation RCBackend

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey
{
    RCHTTPClient *client = [[RCHTTPClient alloc] init];
    return [self initWithHTTPClient:client
                             APIKey:APIKey];
}

- (instancetype _Nullable)initWithHTTPClient:(RCHTTPClient *)client
                                      APIKey:(NSString *)APIKey
{
    if (self = [super init]) {
        self.httpClient = client;
        self.APIKey = APIKey;

        self.receiptCallbacksCache = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)headers
{
    return @{
             @"Authorization":
                 [NSString stringWithFormat:@"Basic %@", self.APIKey]
             };
}

- (NSError *)errorWithBackendMessage:(NSString *)message finishable:(BOOL)finishable
{
    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:(finishable ? RCFinishableError : RCUnfinishableError)
                           userInfo:@{
                                      NSLocalizedDescriptionKey: message
                                      }];
}

- (NSError *)unexpectedResponseError
{
    return [NSError errorWithDomain:RCBackendErrorDomain
                               code:RCUnexpectedBackendResponse
                           userInfo:@{
                                      NSLocalizedDescriptionKey: @"Received malformed response from the backend."
                                      }];
}

- (void)handle:(NSInteger)statusCode
  withResponse:(NSDictionary * _Nullable)response
         error:(NSError * _Nullable)error
    completion:(RCBackendResponseHandler)completion
{

    RCPurchaserInfo *info = nil;
    NSError *responseError = nil;

    if (statusCode < 300) {
        info = [[RCPurchaserInfo alloc] initWithData:response];
        if (info == nil) {
            responseError = [self unexpectedResponseError];
        }
    } else {
        BOOL finishable = (statusCode < 500);
        NSString *message = response[@"message"] ?: @"Unknown backend error.";
        responseError = [self errorWithBackendMessage:message finishable:finishable];
    }

    completion(info, responseError);
}

- (void)handle:(NSInteger)statusCode
  withResponse:(NSDictionary * _Nullable)response
    completion:(void (^)(NSError * _Nullable error))completion
{
    NSError *responseError = nil;
    
    if (statusCode > 300) {
        responseError = [self unexpectedResponseError];
    }
    
    if (completion != nil) {
        completion(responseError);
    }
}

- (NSString *)escapedAppUserID:(NSString *)appUserID {
    return [appUserID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}

- (BOOL)addCallback:(id)completion forKey:(NSString *)key
{
    @synchronized(self) {
        NSMutableArray *callbacks = [self.receiptCallbacksCache objectForKey:key];
        BOOL cacheMiss = callbacks == nil;
        
        if (cacheMiss) {
            callbacks = [NSMutableArray new];
            self.receiptCallbacksCache[key] = callbacks;
        }
        
        [callbacks addObject:[completion copy]];
        
        BOOL shouldReturn = !cacheMiss;
        return shouldReturn;
    }
}

- (NSMutableArray *)getCallbacksAndClearForKey:(NSString *)key {
    @synchronized(self) {
        NSMutableArray *callbacks = self.receiptCallbacksCache[key];
        NSParameterAssert(callbacks);
        
        self.receiptCallbacksCache[key] = nil;
        
        return callbacks;
    }
}

- (void)postReceiptData:(NSData *)data
              appUserID:(NSString *)appUserID
              isRestore:(BOOL)isRestore
      productIdentifier:(NSString *)productIdentifier
                  price:(NSDecimalNumber *)price
            paymentMode:(RCPaymentMode)paymentMode
      introductoryPrice:(NSDecimalNumber *)introductoryPrice
           currencyCode:(NSString *)currencyCode
             completion:(RCBackendResponseHandler)completion
{
    NSString *fetchToken = [data base64EncodedStringWithOptions:0];
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithDictionary:
                                 @{
                                   @"fetch_token": fetchToken,
                                   @"app_user_id": appUserID,
                                   @"is_restore": @(isRestore)
                                   }];

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@-%@-%@",
                          appUserID,
                          @(isRestore),
                          fetchToken,
                          productIdentifier,
                          price,
                          currencyCode,
                          @((NSUInteger)paymentMode),
                          introductoryPrice];
    
    if ([self addCallback:completion forKey:cacheKey]) {
        return;
    }

    if (productIdentifier) {
        body[@"product_id"] = productIdentifier;
    }

    if (price) {
        body[@"price"] = price;
    }

    if (currencyCode) {
        body[@"currency"] = currencyCode;
    }

    if (paymentMode != RCPaymentModeNone) {
        body[@"payment_mode"] = @((NSUInteger)paymentMode);
    }

    if (introductoryPrice) {
        body[@"introductory_price"] = introductoryPrice;
    }

    [self.httpClient performRequest:@"POST"
                               path:@"/receipts"
                               body:body
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      for (RCBackendResponseHandler callback in [self getCallbacksAndClearForKey:cacheKey]) {
                          [self handle:status withResponse:response error:error completion:callback];
                      }
                  }];
}

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendResponseHandler)completion
{
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@", escapedAppUserID];
    
    if ([self addCallback:completion forKey:path]) {
        return;
    }

    [self.httpClient performRequest:@"GET"
                               path:path
                               body:nil
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      for (RCBackendResponseHandler completion in [self getCallbacksAndClearForKey:path]) {
                          [self handle:status withResponse:response error:error completion:completion];
                      }
                  }];
}

- (void)getIntroEligibilityForAppUserID:(NSString *)appUserID
                            receiptData:(NSData *)receiptData
                     productIdentifiers:(NSArray<NSString *> *)productIdentifiers
                             completion:(RCIntroEligibilityResponseHandler)completion
{
    if (productIdentifiers.count == 0) {
        completion(@{});
        return;
    }

    NSString *fetchToken = [receiptData base64EncodedStringWithOptions:0];

    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/intro_eligibility", escapedAppUserID];
    [self.httpClient performRequest:@"POST"
                               path:path
                               body:@{
                                      @"product_identifiers": productIdentifiers,
                                      @"fetch_token": fetchToken
                                      }
                            headers:self.headers
                  completionHandler:^(NSInteger statusCode, NSDictionary * _Nullable response, NSError * _Nullable error) {
                      if (statusCode >= 300) {
                          response = @{};
                      }

                      NSMutableDictionary *eligibilties = [NSMutableDictionary new];
                      for (NSString *productID in productIdentifiers) {
                          NSNumber *e = response[productID];
                          RCIntroEligibityStatus status;
                          if (e == nil || [e isKindOfClass:[NSNull class]]) {
                              status = RCIntroEligibityStatusUnknown;
                          } else if ([e boolValue]) {
                              status = RCIntroEligibityStatusEligible;
                          } else {
                              status = RCIntroEligibityStatusIneligible;
                          }

                          eligibilties[productID] = [[RCIntroEligibility alloc] initWithEligibilityStatus:status];
                      }

                      completion([NSDictionary dictionaryWithDictionary:eligibilties]);
    }];
}

- (NSDictionary<NSString *, RCEntitlement *> *)parseEntitlementResponse:(NSDictionary *)response
{
    NSMutableDictionary *entitlements = [NSMutableDictionary new];

    NSDictionary *entitlementsResponse = response[@"entitlements"];

    for (NSString *proID in entitlementsResponse) {
        NSDictionary *entDict = entitlementsResponse[proID];

        NSMutableDictionary *offerings = [NSMutableDictionary new];
        NSDictionary *offeringsResponse = entDict[@"offerings"];

        for (NSString *offeringID in offeringsResponse) {
            NSDictionary *offDict = offeringsResponse[offeringID];

            RCOffering *offering = [[RCOffering alloc] init];
            offering.activeProductIdentifier = offDict[@"active_product_identifier"];

            offerings[offeringID] = offering;

        }
        entitlements[proID] = [[RCEntitlement alloc] initWithOfferings:offerings];
    }

    return [NSDictionary dictionaryWithDictionary:entitlements];
}

- (void)getEntitlementsForAppUserID:(NSString *)appUserID
                         completion:(RCEntitlementResponseHandler)completion
{
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/products", escapedAppUserID];
    [self.httpClient performRequest:@"GET"
                               path:path
                               body:nil
                            headers:self.headers
                  completionHandler:^(NSInteger statusCode, NSDictionary * _Nullable response, NSError * _Nullable error) {
                      if (statusCode < 300) {
                          NSDictionary *entitlements = [self parseEntitlementResponse:response];
                          completion(entitlements, nil);
                      } else {
                          completion(nil, [self unexpectedResponseError]);
                      }
    }];
}

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
               forAppUserID:(NSString *)appUserID
{
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/attribution", escapedAppUserID];

    [self.httpClient performRequest:@"POST"
                               path:path
                               body:@{
                                      @"network": @(network),
                                      @"data": data
                                      }
                            headers:self.headers
                  completionHandler:nil];
}

- (void)createAliasForAppUserID:(NSString *)appUserID
               withNewAppUserID:(NSString *)newAppUserID
                     completion:(void (^ _Nullable)(NSError * _Nullable error))completion
{
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/alias", escapedAppUserID];
    [self.httpClient performRequest:@"POST"
                               path:path
                               body:@{
                                       @"new_app_user_id": newAppUserID
                               }
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      [self handle:status withResponse:response completion:completion];
                  }];
}

@end
