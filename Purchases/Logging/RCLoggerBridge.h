//
//  RCLogger.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2021 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCLogLevel.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Purchases.Logger)
@interface RCLoggerBridge : NSObject

/**
 Set a custom log handler for redirecting logs to your own logging system.
 
 By default, this sends Info, Warn, and Error messages. If you wish to receive Debug level messages, you must enable debug logs.
 */
+ (void)setLogHandler:(void(^)(RCLogLevel, NSString * _Nonnull))logHandler;

/**
 Used to set the log level. Useful for debugging issues with the lovely team @RevenueCat
*/
@property (class, nonatomic) RCLogLevel logLevel;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
