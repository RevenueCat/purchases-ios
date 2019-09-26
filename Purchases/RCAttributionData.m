//
//  RCAttributionData.m
//  Purchases
//
//  Created by César de la Vega  on 4/23/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCAttributionData.h"

@implementation RCAttributionData

- (nullable instancetype)initWithData:(NSDictionary *)data fromNetwork:(RCAttributionNetwork)network forNetworkUserId:(nullable NSString *)networkUserId
{
    if (self = [super init]) {
        self.data = data;
        self.network = network;
        self.networkUserId = networkUserId;
    }
    return self;
}

@end
