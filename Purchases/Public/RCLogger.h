//
//  RCLogger.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2021 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RCLogLevel) {
    RCLogLevelDebug,
    RCLogLevelInfo,
    RCLogLevelWarn,
    RCLogLevelError,
} NS_SWIFT_NAME(Purchases.LogLevel);

NS_SWIFT_NAME(Purchases.Logger)
@interface RCLogger : NSObject

/**
 Set a custom log handler for redirecting logs to your own logging system.
 
 By default, this sends Info, Warn, and Error messages. If you wish to receive Debug level messages, you must enable debug logs.
 */
+ (void)setLogHandler:(void(^)(RCLogLevel, NSString * _Nonnull))logHandler;

/**
 Enable debug logging. Useful for debugging issues with the lovely team @RevenueCat
*/
@property (class, nonatomic) BOOL debugLogsEnabled;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
