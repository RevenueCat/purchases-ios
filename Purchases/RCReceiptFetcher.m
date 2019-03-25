//
//  RCReceiptFetcher.m
//  Purchases
//
//  Created by César de la Vega  on 3/6/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCReceiptFetcher.h"
#import "RCUtils.h"

@implementation RCReceiptFetcher : NSObject

- (NSData *)receiptData
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *data = [NSData dataWithContentsOfURL:receiptURL];
    RCDebugLog(@"Loaded receipt from %@", receiptURL);
    return data;
}

@end

