//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo : NSObject

+ (BOOL)isSandbox;
+ (NSString *)frameworkVersion;
+ (NSString *)systemVersion;
+ (NSString *)appVersion;
+ (NSString *)platformHeader;
+ (NSString *)platformFlavor;

@end


NS_ASSUME_NONNULL_END
