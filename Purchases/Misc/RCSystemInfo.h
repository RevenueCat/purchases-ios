//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo : NSObject

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                 platformFlavorVersion:(nullable NSString *)platformFlavorVersion
                    finishTransactions:(BOOL)finishTransactions NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, assign) BOOL finishTransactions;
@property(nonatomic, copy, readonly) NSString *platformFlavor;
@property(nonatomic, copy, readonly) NSString *platformFlavorVersion;

+ (BOOL)isSandbox;
+ (NSString *)frameworkVersion;
+ (NSString *)systemVersion;
+ (NSString *)appVersion;
+ (NSString *)platformHeader;

+ (NSString *)serverHostName;
+ (nullable NSString *)proxyURL;
+ (void)setProxyURL:(nullable NSString *)newProxyURL;

@end


NS_ASSUME_NONNULL_END
