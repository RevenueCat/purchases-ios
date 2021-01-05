//
// Created by Andrés Boedo on 1/4/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class RCPurchaserInfo;
typedef void (^RCReceivePurchaserInfoBlock)(RCPurchaserInfo * _Nullable, NSError * _Nullable) NS_SWIFT_NAME(Purchases.ReceivePurchaserInfoBlock);

@interface RCPurchaserInfoManager : NSObject

- (void)fetchAndCachePurchaserInfoWithAppUserID:(NSString *)appUserID
                              isAppBackgrounded:(BOOL)isAppBackgrounded
                                     completion:(nullable RCReceivePurchaserInfoBlock)completion;

@end


NS_ASSUME_NONNULL_END
