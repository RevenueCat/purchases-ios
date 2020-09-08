//
//  RCBackend.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCBackend.h"

#import "RCHTTPClient.h"
#import "RCPurchaserInfo+Protected.h"
#import "RCIntroEligibility.h"
#import "RCIntroEligibility+Protected.h"
#import "RCPurchasesErrorUtils.h"
#import "RCPurchasesErrorUtils+Protected.h"
#import "RCLogUtils.h"
#import "RCSystemInfo.h"
#import "RCHTTPStatusCodes.h"

#define RC_HAS_KEY(dictionary, key) (dictionary[key] == nil || dictionary[key] != [NSNull null])
NSErrorUserInfoKey const RCSuccessfullySyncedKey = @"successfullySynced";
NSString *const RCAttributeErrorsKey = @"attribute_errors";
NSString *const RCAttributeErrorsResponseKey = @"attributes_error_response";

@interface RCBackend ()

@property (nonatomic) RCHTTPClient *httpClient;
@property (nonatomic) NSString *APIKey;

@property (nonatomic) NSMutableDictionary<NSString *, NSMutableArray *> *callbacksCache;

@end

@implementation RCBackend

- (nullable instancetype)initWithAPIKey:(NSString *)APIKey systemInfo:(RCSystemInfo *)systemInfo {
    RCHTTPClient *client = [[RCHTTPClient alloc] initWithSystemInfo:systemInfo];
    return [self initWithHTTPClient:client
                             APIKey:APIKey];
}

- (nullable instancetype)initWithHTTPClient:(RCHTTPClient *)client
                                     APIKey:(NSString *)APIKey {
    if (self = [super init]) {
        self.httpClient = client;
        self.APIKey = APIKey;

        self.callbacksCache = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)headers
{
    return @{
            @"Authorization":
                [NSString stringWithFormat:@"Bearer %@", self.APIKey]
            };
}

- (void)handle:(NSInteger)statusCode
  withResponse:(nullable NSDictionary *)response
         error:(nullable NSError *)error
    completion:(RCBackendPurchaserInfoResponseHandler)completion
{
    if (error != nil) {
        completion(nil, [RCPurchasesErrorUtils networkErrorWithUnderlyingError:error]);
        return;
    }

    RCPurchaserInfo *info = nil;
    NSError *responseError = nil;
    BOOL isErrorStatusCode = (statusCode >= RC_REDIRECT);

    if (!isErrorStatusCode) {
        info = [[RCPurchaserInfo alloc] initWithData:response];
        if (info == nil) {
            responseError = [RCPurchasesErrorUtils unexpectedBackendResponseError];
            completion(info, responseError);
            return;
        }
    }

    NSDictionary *subscriberAttributesErrorInfo = [self attributesUserInfoFromResponse:response
                                                                            statusCode:statusCode];

    BOOL hasError = (isErrorStatusCode || subscriberAttributesErrorInfo[RCAttributeErrorsKey] != nil);

    if (hasError) {
        BOOL finishable = (statusCode < RC_INTERNAL_SERVER_ERROR);
        NSMutableDictionary *extraUserInfo = @{
            RCFinishableKey: @(finishable)
        }.mutableCopy;
        [extraUserInfo addEntriesFromDictionary:subscriberAttributesErrorInfo];
        responseError = [RCPurchasesErrorUtils backendErrorWithBackendCode:response[@"code"]
                                                            backendMessage:response[@"message"]
                                                             extraUserInfo:extraUserInfo];
    }
    completion(info, responseError);
}

- (void)handle:(NSInteger)statusCode
  withResponse:(nullable NSDictionary *)response
         error:(nullable NSError *)error
  errorHandler:(void (^)(NSError * _Nullable error))errorHandler
{

    if (error != nil) {
        errorHandler([RCPurchasesErrorUtils networkErrorWithUnderlyingError:error]);
        return;
    }

    NSError *responseError = nil;

    if (statusCode > RC_REDIRECT) {
        responseError = [RCPurchasesErrorUtils backendErrorWithBackendCode:response[@"code"]
                                                            backendMessage:response[@"message"]];
    }

    if (errorHandler != nil) {
        errorHandler(responseError);
    }
}

- (NSString *)escapedAppUserID:(NSString *)appUserID {
    return [appUserID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}

- (BOOL)addCallback:(id)completion forKey:(NSString *)key
{
    @synchronized(self) {
        NSMutableArray *callbacks = self.callbacksCache[key];
        BOOL cacheMiss = callbacks == nil;

        if (cacheMiss) {
            callbacks = [NSMutableArray new];
            self.callbacksCache[key] = callbacks;
        }

        [callbacks addObject:[completion copy]];

        BOOL requestAlreadyInFlight = !cacheMiss;
        return requestAlreadyInFlight;
    }
}

- (NSMutableArray *)getCallbacksAndClearForKey:(NSString *)key {
    @synchronized(self) {
        NSMutableArray *callbacks = self.callbacksCache[key];
        NSParameterAssert(callbacks);

        self.callbacksCache[key] = nil;

        return callbacks;
    }
}

- (void)    postReceiptData:(NSData *)data
                  appUserID:(NSString *)appUserID
                  isRestore:(BOOL)isRestore
                productInfo:(nullable RCProductInfo *)productInfo
presentedOfferingIdentifier:(nullable NSString *)offeringIdentifier
               observerMode:(BOOL)observerMode
       subscriberAttributes:(nullable RCSubscriberAttributeDict)subscriberAttributesByKey
                 completion:(RCBackendPurchaserInfoResponseHandler)completion {
    NSString *fetchToken = [data base64EncodedStringWithOptions:0];
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithDictionary:
                                                         @{
                                                             @"fetch_token": fetchToken,
                                                             @"app_user_id": appUserID,
                                                             @"is_restore": @(isRestore),
                                                             @"observer_mode": @(observerMode)
                                                         }];

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@-%@",
                                                    appUserID,
                                                    @(isRestore),
                                                    fetchToken,
                                                    productInfo.cacheKey,
                                                    offeringIdentifier,
                                                    @(observerMode),
                                                    subscriberAttributesByKey];

    if ([self addCallback:completion forKey:cacheKey]) {
        return;
    }

    if (productInfo) {
        [body addEntriesFromDictionary:productInfo.asDictionary];
    }

    if (subscriberAttributesByKey) {
        NSDictionary *attributesInBackendFormat = [self subscriberAttributesByKey:subscriberAttributesByKey];
        body[@"attributes"] = attributesInBackendFormat;
    }

    if (offeringIdentifier) {
        body[@"presented_offering_identifier"] = offeringIdentifier;
    }

    [self.httpClient performRequest:@"POST"
                               path:@"/receipts"
                               body:body
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *response, NSError *error) {
                      NSArray *callbacks = [self getCallbacksAndClearForKey:cacheKey];
                      for (RCBackendPurchaserInfoResponseHandler callback in callbacks) {
                          [self handle:status withResponse:response error:error completion:callback];
                      }
                  }];
}

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendPurchaserInfoResponseHandler)completion
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
                      for (RCBackendPurchaserInfoResponseHandler completion in [self getCallbacksAndClearForKey:path]) {
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
    if (receiptData.length == 0) {
        if (RCSystemInfo.isSandbox) {
            RCLog(@"App running on sandbox without a receipt file. Unable to determine into eligibility unless you've purchased before and there is a receipt available.");
        }
        NSMutableDictionary *eligibilities = [NSMutableDictionary new];
        for (NSString *productID in productIdentifiers) {
            eligibilities[productID] = [[RCIntroEligibility alloc] initWithEligibilityStatus:RCIntroEligibilityStatusUnknown];
        }
        completion([NSDictionary dictionaryWithDictionary:eligibilities]);
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
                      if (statusCode >= RC_REDIRECT || error != nil) {
                          response = @{};
                      }

                      NSMutableDictionary *eligibilities = [NSMutableDictionary new];
                      for (NSString *productID in productIdentifiers) {
                          NSNumber *e = response[productID];
                          RCIntroEligibilityStatus status;
                          if (e == nil || [e isKindOfClass:[NSNull class]]) {
                              status = RCIntroEligibilityStatusUnknown;
                          } else if ([e boolValue]) {
                              status = RCIntroEligibilityStatusEligible;
                          } else {
                              status = RCIntroEligibilityStatusIneligible;
                          }

                          eligibilities[productID] = [[RCIntroEligibility alloc] initWithEligibilityStatus:status];
                      }

                      completion([NSDictionary dictionaryWithDictionary:eligibilities]);
    }];
}

- (void)getOfferingsForAppUserID:(NSString *)appUserID
                      completion:(RCOfferingsResponseHandler)completion
{
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/offerings", escapedAppUserID];

    if ([self addCallback:completion forKey:path]) {
        return;
    }

    [self.httpClient performRequest:@"GET"
                               path:path
                               body:nil
                            headers:self.headers
                  completionHandler:^(NSInteger statusCode, NSDictionary * _Nullable response, NSError * _Nullable error) {
                      if (error == nil && statusCode < RC_REDIRECT) {
                          for (RCOfferingsResponseHandler callback in [self getCallbacksAndClearForKey:path]) {
                              callback(response, nil);
                          }
                          return;
                      }

                      if (error != nil) {
                          error = [RCPurchasesErrorUtils networkErrorWithUnderlyingError:error];
                      } else if (statusCode > RC_REDIRECT) {
                          error = [RCPurchasesErrorUtils backendErrorWithBackendCode:response[@"code"]
                                                                      backendMessage:response[@"message"]];
                      }
                      for (RCOfferingsResponseHandler callback in [self getCallbacksAndClearForKey:path]) {
                          callback(nil, error);
                      }
                  }];
}

- (void)postAttributionData:(NSDictionary *)data
                fromNetwork:(RCAttributionNetwork)network
               forAppUserID:(NSString *)appUserID
                 completion:(nullable void (^)(NSError * _Nullable error))completion
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
                  completionHandler:^(NSInteger status, NSDictionary *_Nullable response, NSError *_Nullable error) {
                      [self handle:status withResponse:response error:error errorHandler:completion];
                  }];
}

- (void)createAliasForAppUserID:(NSString *)appUserID
               withNewAppUserID:(NSString *)newAppUserID
                     completion:(nullable void (^)(NSError * _Nullable error))completion
{
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/alias", escapedAppUserID];
    [self.httpClient performRequest:@"POST"
                               path:path
                               body:@{
                                       @"new_app_user_id": newAppUserID
                               }
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *_Nullable response, NSError *_Nullable error) {
                      [self handle:status withResponse:response error:error errorHandler:completion];
                  }];
}


- (void)postOfferForSigning:(NSString *)offerIdentifier
      withProductIdentifier:(NSString *)productIdentifier
          subscriptionGroup:(NSString *)subscriptionGroup
                receiptData:(NSData *)receiptData
                  appUserID:(NSString *)appUserID
                 completion:(RCOfferSigningResponseHandler)completion
{
    NSString *fetchToken = [receiptData base64EncodedStringWithOptions:0];
    [self.httpClient performRequest:@"POST" path:@"/offers"
                               body:@{
                                       @"app_user_id": appUserID,
                                       @"fetch_token": fetchToken,
                                       @"generate_offers": @[@{
                                               @"offer_id": offerIdentifier,
                                               @"product_id": productIdentifier,
                                               @"subscription_group": subscriptionGroup
                                       }],
                               }
                            headers:self.headers
                  completionHandler:^(NSInteger statusCode, NSDictionary *_Nullable response, NSError *_Nullable error) {
                      if (error != nil) {
                          completion(nil, nil, nil, nil, [RCPurchasesErrorUtils networkErrorWithUnderlyingError:error]);
                          return;
                      }

                      NSArray *offers = nil;

                      if (statusCode < RC_REDIRECT) {
                          offers = response[@"offers"];
                          if (offers == nil || offers.count == 0) {
                              error = [RCPurchasesErrorUtils unexpectedBackendResponseError];
                          } else {
                            NSDictionary *offer = offers[0];
                            if (RC_HAS_KEY(offer, @"signature_error")) {
                                error = [RCPurchasesErrorUtils backendErrorWithBackendCode:offer[@"signature_error"][@"code"] backendMessage:offer[@"signature_error"][@"message"]];
                            } else if (RC_HAS_KEY(offer, @"signature_data")) {
                                NSDictionary *signatureData = offer[@"signature_data"];
                                NSString *signature = signatureData[@"signature"];
                                NSString *keyIdentifier = offer[@"key_id"];
                                NSUUID *nonce = [[NSUUID alloc] initWithUUIDString:signatureData[@"nonce"]];
                                NSNumber *timestamp = signatureData[@"timestamp"];
                                completion(signature, keyIdentifier, nonce, timestamp, nil);
                                return;
                            } else {
                                error = [RCPurchasesErrorUtils unexpectedBackendResponseError];
                            }
                          }
                      } else {
                          error = [RCPurchasesErrorUtils backendErrorWithBackendCode:response[@"code"] backendMessage:response[@"message"]];
                      }

                      completion(nil, nil, nil, nil, error);
                  }];
}

- (void)postSubscriberAttributes:(RCSubscriberAttributeDict)subscriberAttributes
                       appUserID:(NSString *)appUserID
                      completion:(nullable void (^)(NSError *_Nullable error))completion {
    if (subscriberAttributes.count == 0) {
        RCLog(@"called post subscriber attributes with an empty attributes dict!");
        return;
    }
    NSString *escapedAppUserID = [self escapedAppUserID:appUserID];
    NSString *path = [NSString stringWithFormat:@"/subscribers/%@/attributes", escapedAppUserID];
    NSDictionary *attributesInBackendFormat = [self subscriberAttributesByKey:subscriberAttributes];
    [self.httpClient performRequest:@"POST"
                               path:path
                               body:@{
                                   @"attributes": attributesInBackendFormat
                               }
                            headers:self.headers
                  completionHandler:^(NSInteger status, NSDictionary *_Nullable response, NSError *_Nullable error) {
                      [self handleSubscriberAttributesResultWithStatusCode:status
                                                                  response:response
                                                                     error:error
                                                                completion:completion];
                  }];

}

- (NSDictionary<NSString *, NSDictionary *> *)subscriberAttributesByKey:(RCSubscriberAttributeDict)subscriberAttributes {
    NSMutableDictionary <NSString *, NSDictionary *> *attributesByKey = [[NSMutableDictionary alloc] init];
    for (NSString *key in subscriberAttributes) {
        attributesByKey[key] = subscriberAttributes[key].asBackendDictionary;
    }
    return attributesByKey;
}

- (void)handleSubscriberAttributesResultWithStatusCode:(NSInteger)statusCode
                                              response:(nullable NSDictionary *)response
                                                 error:(nullable NSError *)error
                                            completion:(void (^)(NSError *_Nullable error))completion {

    if (completion == nil) {
        return;
    }

    if (error != nil) {
        completion([RCPurchasesErrorUtils networkErrorWithUnderlyingError:error]);
        return;
    }
    NSError *responseError = nil;

    if (statusCode > RC_REDIRECT) {
        NSDictionary *extraUserInfo = [self attributesUserInfoFromResponse:response
                                                                statusCode:statusCode];
        responseError = [RCPurchasesErrorUtils backendErrorWithBackendCode:response[@"code"]
                                                            backendMessage:response[@"message"]
                                                             extraUserInfo:extraUserInfo];
    }

    completion(responseError);
}

- (NSDictionary *)attributesUserInfoFromResponse:(NSDictionary *)response statusCode:(NSInteger)statusCode {
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    BOOL isInternalServerError = statusCode >= RC_INTERNAL_SERVER_ERROR;
    BOOL isNotFoundError = statusCode == RC_NOT_FOUND_ERROR;
    BOOL successfullySynced = !(isInternalServerError || isNotFoundError);
    resultDict[RCSuccessfullySyncedKey] = @(successfullySynced);

    BOOL hasAttributesResponseContainerKey = (response[RCAttributeErrorsResponseKey] != nil);
    NSDictionary *attributesResponseDict = hasAttributesResponseContainerKey
                                           ? response[RCAttributeErrorsResponseKey]
                                           : response;

    BOOL hasAttributeErrors = (attributesResponseDict[RCAttributeErrorsKey] != nil);
    if (hasAttributeErrors) {
        resultDict[RCAttributeErrorsKey] = attributesResponseDict[RCAttributeErrorsKey];
    }
    return resultDict;
}

@end
