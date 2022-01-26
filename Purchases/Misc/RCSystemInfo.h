//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCDangerousSettings;
@interface RCSystemInfo : NSObject

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                 platformFlavorVersion:(nullable NSString *)platformFlavorVersion
                    finishTransactions:(BOOL)finishTransactions;

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                 platformFlavorVersion:(nullable NSString *)platformFlavorVersion
                    finishTransactions:(BOOL)finishTransactions
                     dangerousSettings:(nullable RCDangerousSettings *)dangerousSettings NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, assign) BOOL finishTransactions;
@property(nonatomic, copy, readonly) NSString *platformFlavor;
@property(nonatomic, copy, readonly) NSString *platformFlavorVersion;
@property(class, nonatomic, assign) BOOL forceUniversalAppStore;
@property(nonatomic, readonly) RCDangerousSettings *dangerousSettings;

- (void)isApplicationBackgroundedWithCompletion:(void(^)(BOOL))completion; // calls completion on the main thread
- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version;

+ (BOOL)isSandbox;
+ (NSString *)frameworkVersion;
+ (NSString *)systemVersion;
+ (NSString *)appVersion;
+ (NSString *)buildVersion;
+ (NSString *)platformHeader;
+ (nullable NSString *)identifierForVendor;

+ (NSURL *)serverHostURL;
+ (nullable NSURL *)proxyURL;
+ (void)setProxyURL:(nullable NSURL *)newProxyURL;

@end


NS_ASSUME_NONNULL_END
