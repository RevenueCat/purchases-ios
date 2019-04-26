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

- (instancetype _Nullable)initWithData:(NSDictionary *)data fromNetwork:(RCAttributionNetwork)network forNetworkUserId:(NSString *_Nullable)networkUserId
{
    if (self = [super init]) {
        self.data = data;
        self.network = network;
        self.networkUserId = networkUserId;
    }
    return self;
}

@end
