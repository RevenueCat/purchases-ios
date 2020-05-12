//
//  RCReceiptFetcher.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface RCReceiptFetcher : NSObject

- (NSData *)receiptData;

@end
