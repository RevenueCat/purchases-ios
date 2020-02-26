//
// Created by RevenueCat on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"

NS_ASSUME_NONNULL_BEGIN

#define KEY_KEY @"key"
#define VALUE_KEY @"value"
#define APP_USER_ID_KEY @"appUserID"
#define SET_TIME_KEY @"setTime"
#define IS_SYNCED_KEY @"isSynced"

#define BACKEND_VALUE_KEY @"value"
#define BACKEND_TIMESTAMP_KEY @"updated_at"


@interface RCSubscriberAttribute ()

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *appUserID;
@property (nonatomic) NSDate *setTime;

@end


NS_ASSUME_NONNULL_END


@implementation RCSubscriberAttribute

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID {
    return [self initWithKey:key
                       value:value
                   appUserID:appUserID
                    isSynced:NO
                     setTime:[NSDate date]];
}

- (instancetype)initWithKey:(NSString *)key
                      value:(NSString *)value
                  appUserID:(NSString *)appUserID
                   isSynced:(BOOL)isSynced
                    setTime:(NSDate *)setTime {
    if (self = [super init]) {
        self.key = key;
        self.value = value;
        self.appUserID = appUserID;
        self.isSynced = isSynced;
        self.setTime = setTime;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSObject *> *)dict {
    return [self initWithKey:(NSString *) dict[KEY_KEY]
                       value:(NSString *) dict[VALUE_KEY]
                   appUserID:(NSString *) dict[APP_USER_ID_KEY]
                    isSynced:((NSNumber *) dict[IS_SYNCED_KEY]).boolValue
                     setTime:(NSDate *) dict[SET_TIME_KEY]];
}

- (NSDictionary <NSString *, NSObject *> *)asDictionary {
    return @{
        KEY_KEY: self.key,
        VALUE_KEY: self.value ?: @"",
        APP_USER_ID_KEY: self.appUserID,
        IS_SYNCED_KEY: @(self.isSynced),
        SET_TIME_KEY: self.setTime,
    };
}

- (NSDictionary <NSString *, NSObject *> *)asBackendDictionary {
    return @{
        BACKEND_VALUE_KEY: self.value ?: @"",
        BACKEND_TIMESTAMP_KEY: @(self.setTime.timeIntervalSince1970)
    };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Subscriber attribute: key: %@ value: %@ appUserID: %@ setTime: %@",
                                      self.key, self.value, self.appUserID, self.setTime];
}

@end
