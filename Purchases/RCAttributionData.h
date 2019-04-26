//
//  RCAttributionData.h
//  Purchases
//
//  Created by César de la Vega  on 4/23/19.
//  Copyright © 2019 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Purchases/Purchases.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCAttributionData : NSObject

@property (readwrite, nonatomic) NSDictionary *data;
@property (readwrite, nonatomic) RCAttributionNetwork network;
@property (readwrite, nonatomic) NSString * _Nullable networkUserId;

- (instancetype _Nullable)initWithData:(NSDictionary *)data fromNetwork:(RCAttributionNetwork)network forNetworkUserId:(NSString * _Nullable)networkUserId;

@end

NS_ASSUME_NONNULL_END
