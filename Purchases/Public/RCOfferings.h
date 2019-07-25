//
//  RCOfferings.h
//  Purchases
//
//  Created by Jacob Eiting on 7/23/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOffering;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Offerings)
@interface RCOfferings : NSObject

@property (readonly) RCOffering * currentOffering NS_SWIFT_NAME(current);

- (RCOffering * _Nullable)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(RCOffering *)obj forKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
