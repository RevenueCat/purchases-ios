//
// Created by Andrés Boedo on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCSubscriberAttribute.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttribute ()

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, copy) NSString *appUserID;
@property(nonatomic) NSDate *syncStartedTime;
@property(nonatomic) NSDate *setTime;
@property(nonatomic, assign) BOOL isSynced;

@end


NS_ASSUME_NONNULL_END


@implementation RCSubscriberAttribute

- (NSDictionary <NSString *, NSObject *> *)asDictionary {
    return @{
        self.key: self.value,
        @"appID": self.appID,
        @"appUserID": self.appUserID,
        @"syncStartedTime": self.syncStartedTime,
        @"isSynced": @(self.isSynced),
    };
}

- (NSString *)asJSON {
    NSDictionary *backendFormatDict = [self convertToBackendFormat];
    return [self jsonFromDict:backendFormatDict];
}

- (NSDictionary *)convertToBackendFormat {
    return @{
        self.key: @{
                @"value": self.value,
                @"timestamp": @(self.setTime.timeIntervalSince1970)
            }
        };
}

#pragma private methods

- (NSString *)jsonFromDict:(NSDictionary <NSString *, NSObject *> *)fromDict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fromDict
                                                       options:0
                                                         error:&error];

    if (!jsonData) {
        NSLog(@"failed when converting to json: %@", error.localizedDescription);
        @throw([NSException exceptionWithName:@"ConvertToJSONError"
                                       reason:@"couldn't convert dict to json"
                                     userInfo:nil]);
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end
