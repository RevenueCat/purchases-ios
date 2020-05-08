//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo : NSObject

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                          observerMode:(BOOL)observerMode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, assign) BOOL observerMode;
@property(nonatomic, copy, readonly) NSString *platformFlavor;

+ (BOOL)isSandbox;
+ (NSString *)frameworkVersion;
+ (NSString *)systemVersion;
+ (NSString *)appVersion;
+ (NSString *)platformHeader;

@end


NS_ASSUME_NONNULL_END
