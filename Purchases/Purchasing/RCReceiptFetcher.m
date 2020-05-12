//
//  RCReceiptFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCReceiptFetcher.h"
#import "RCLogUtils.h"

@implementation RCReceiptFetcher : NSObject

- (NSData *)receiptData
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *data = [NSData dataWithContentsOfURL:receiptURL];
    RCDebugLog(@"Loaded receipt from %@", receiptURL);
    return data;
}

@end

