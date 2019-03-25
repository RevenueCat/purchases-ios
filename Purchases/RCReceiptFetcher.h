//
//  RCReceiptFetcher.h
//  Purchases
//
//  Created by César de la Vega  on 3/6/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface RCReceiptFetcher : NSObject

- (NSData *)receiptData;

@end
