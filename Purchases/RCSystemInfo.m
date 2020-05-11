//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSystemInfo.h"
#import "RCCrossPlatformSupport.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo()

@property(nonatomic, copy, nullable) NSString *platformFlavor;

@end

@implementation RCSystemInfo

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                    finishTransactions:(BOOL)finishTransactions {
    if (self = [super init]) {
        if (!platformFlavor) {
            platformFlavor = @"native";
        }
        self.platformFlavor = platformFlavor;
        self.finishTransactions = finishTransactions;
    }
    return self;
}

+ (BOOL)isSandbox {
    NSURL *url = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *receiptURLString = url.path;
    return ([receiptURLString rangeOfString:@"sandboxReceipt"].location != NSNotFound);
}

+ (NSString *)frameworkVersion {
    return @"3.3.0-SNAPSHOT";
}

+ (NSString *)systemVersion {
    NSProcessInfo *info = [[NSProcessInfo alloc] init];
    return info.operatingSystemVersionString;
}

+ (NSString *)appVersion {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return version ?: @"";
}

+ (NSString *)platformHeader {
    return PLATFORM_HEADER;
}

@end


NS_ASSUME_NONNULL_END
