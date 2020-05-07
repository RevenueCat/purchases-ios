//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSystemInfo.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo ()


@end


@implementation RCSystemInfo

+ (BOOL)isSandbox {
    NSURL *url = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *receiptURLString = url.path;
    return ([receiptURLString rangeOfString:@"sandboxReceipt"].location != NSNotFound);
}

+ (NSString *)frameworkVersion {
    return @"3.3.0-SNAPSHOT";
}

+ (NSString *)systemVersion {
    return nil;
}

+ (NSString *)appVersion {
    return nil;
}

+ (NSString *)platformHeader {
    return nil;
}

+ (NSString *)platformFlavor {
    return nil;
}

@end


NS_ASSUME_NONNULL_END
