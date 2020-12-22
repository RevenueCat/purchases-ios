//
//  RCReceiptFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCReceiptFetcher.h"
#import "RCLogUtils.h"
@import PurchasesCoreSwift;
#import "RCSystemInfo.h"

@implementation RCReceiptFetcher : NSObject

- (NSData *)receiptData {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    
#if TARGET_OS_WATCH
    // as of watchOS 6.2.8, there's a bug where the receipt is stored in the sandbox receipt location,
    // but the appStoreReceiptURL method returns the URL for the production receipt.
    // This code replaces "sandboxReceipt" with "receipt" as the last component of the receiptURL so that we get the
    // correct receipt.
    // This has been filed as radar FB7699277. More info in https://github.com/RevenueCat/purchases-ios/issues/207.
    
    NSOperatingSystemVersion minimumOSVersionWithoutBug = { .majorVersion = 7, .minorVersion = 0, .patchVersion = 0 };
    BOOL isBelowMinimumOSVersionWithoutBug = ![NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minimumOSVersionWithoutBug];
    if (isBelowMinimumOSVersionWithoutBug && RCSystemInfo.isSandbox) {
        NSString *receiptURLFolder = [[receiptURL absoluteString] stringByDeletingLastPathComponent];
        NSURL *productionReceiptURL = [NSURL URLWithString:[receiptURLFolder stringByAppendingPathComponent:@"receipt"]];
        receiptURL = productionReceiptURL;
    }
#endif
    
    NSData *data = [NSData dataWithContentsOfURL:receiptURL];
    RCDebugLog(RCStrings.receipt.loaded_receipt, receiptURL);
    return data;
}

@end

