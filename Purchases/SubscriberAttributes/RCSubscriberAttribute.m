//
// Created by RevenueCat on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"
#import "RCDateProvider.h"
#import "NSDate+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN

#define KEY_KEY @"key"
#define VALUE_KEY @"value"
#define SET_TIME_KEY @"setTime"
#define IS_SYNCED_KEY @"isSynced"

#define BACKEND_VALUE_KEY @"value"
#define BACKEND_TIMESTAMP_KEY @"updated_at_ms"


@interface RCSubscriberAttribute ()

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic) NSDate *setTime;

@end


NS_ASSUME_NONNULL_END


@implementation RCSubscriberAttribute

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value {
    return [self initWithKey:key
                       value:value
                dateProvider:[[RCDateProvider alloc] init]];
}

- (instancetype)initWithKey:(NSString *)key
                      value:(NSString *)value
                   isSynced:(BOOL)isSynced
                    setTime:(NSDate *)setTime {
    if (self = [super init]) {
        self.key = key;
        self.value = value;
        self.isSynced = isSynced;
        self.setTime = setTime;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key
                      value:(NSString *)value
               dateProvider:(RCDateProvider *)dateProvider {
    return [self initWithKey:key
                       value:value
                    isSynced:NO
                     setTime:dateProvider.now];
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSObject *> *)dict {
    return [self initWithKey:(NSString *) dict[KEY_KEY]
                       value:(NSString *) dict[VALUE_KEY]
                    isSynced:((NSNumber *) dict[IS_SYNCED_KEY]).boolValue
                     setTime:(NSDate *) dict[SET_TIME_KEY]];
}

- (NSDictionary <NSString *, NSObject *> *)asDictionary {
    return @{
        KEY_KEY: self.key,
        VALUE_KEY: self.value ?: @"",
        IS_SYNCED_KEY: @(self.isSynced),
        SET_TIME_KEY: self.setTime,
    };
}

- (NSDictionary <NSString *, NSObject *> *)asBackendDictionary {
    return @{
        BACKEND_VALUE_KEY: self.value ?: @"",
        BACKEND_TIMESTAMP_KEY: @(self.setTime.rc_millisecondsSince1970AsUInt64)
    };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Subscriber attribute: key: %@ value: %@ setTime: %@",
                                      self.key, self.value, self.setTime];
}

- (BOOL)isEqual:(nullable RCSubscriberAttribute *)attribute {
    if (self == attribute)
        return YES;
    if (attribute == nil)
        return NO;
    if (self.key != attribute.key)
        return NO;
    if (self.value != attribute.value)
        return NO;
    if (self.setTime != attribute.setTime && ![self.setTime isEqualToDate:attribute.setTime])
        return NO;
    if (self.isSynced != attribute.isSynced)
        return NO;
    return YES;
}

@end
