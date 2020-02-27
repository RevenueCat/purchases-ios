//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchasesErrorUtils.h"
#import "RCPurchasesErrors.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCPurchasesErrorUtils (Protected)

+ (NSError *)backendErrorWithBackendCode:(nullable NSNumber *)backendCode
                          backendMessage:(nullable NSString *)backendMessage
                           extraUserInfo:(nullable NSDictionary *)extraUserInfo;
@end


NS_ASSUME_NONNULL_END
