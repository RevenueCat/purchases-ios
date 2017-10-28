//
//  RCBackend.h
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCPurchaserInfo, RCHTTPClient;

FOUNDATION_EXPORT NSErrorDomain const RCBackendErrorDomain;
NS_ERROR_ENUM(RCBackendErrorDomain) {
    RCUnexpectedBackendResponse = 0,
    RCBackendError,
    RCErrorParsingPurchaserInfo
};

typedef void(^RCBackendResponseHandler)(RCPurchaserInfo * _Nullable,
                                         NSError * _Nullable);

@interface RCBackend : NSObject

- (instancetype _Nullable)initWithAPIKey:(NSString *)APIKey;

- (instancetype _Nullable)initWithHTTPClient:(RCHTTPClient *)client
                                      APIKey:(NSString *)APIKey;

- (void)postReceiptData:(NSData *)data
              appUserID:(NSString *)appUserID
             completion:(RCBackendResponseHandler)completion;

- (void)getSubscriberDataWithAppUserID:(NSString *)appUserID
                            completion:(RCBackendResponseHandler)completion;

@end

NS_ASSUME_NONNULL_END
