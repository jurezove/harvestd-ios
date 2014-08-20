//
//  Harvest.m
//  Harvest
//
//  Created by Sean McGary on 8/20/14.
//  Copyright (c) 2014 Sean McGary. All rights reserved.
//

#import "Harvest.h"

#define HARVEST_COOKIE @"harvestcookie"

@implementation Harvest

#pragma mark Singleton Methods

+(id) sharedManager {
    __strong static Harvest *harvest = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        harvest = [[self alloc] init];
    });
    return harvest;
}

+(void) trackEvent:(NSString *)event withData:(NSDictionary *)data {
    [[Harvest sharedManager] track:event withData:data];
}

+(void) identifyUser:(NSString *)idToReplace {
    [[Harvest sharedManager] identify:idToReplace];
}

+(void) setApiToken:(NSString *) apiToken andHostname: (NSString *) hostname {
    [[Harvest sharedManager] setApiToken:apiToken];
    [[Harvest sharedManager] setHostname:hostname];
}

+(void) includeData: (NSDictionary *) data {
    [[Harvest sharedManager] alwaysInclude:data];
}

+(NSString *) generateUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

// static methods


-(id) init {
    self = [super init];
    
    if(self){
        self.includeData = @{};
    }
    
    _pretrack = ^void (NSString * eventName, NSDictionary *data, void(^cb)(NSString *, NSDictionary *)){
        NSLog(@"callback dude");
        NSLog(@"%@", eventName);
        NSLog(@"%@", data);
        
        cb(eventName, data);
    };
    
    return self;
}

-(void) setApiToken:(NSString *)token {
    _apiToken = token;
}

-(void) setHostname:(NSString *)host {
    _hostname = host;
}

-(NSNumber *) getTimestamp {
    return [[NSNumber alloc] initWithInt: (int)[[[NSDate alloc] init] timeIntervalSince1970]];
}

-(NSDictionary *) getUserCookie {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *cookie = (NSDictionary *)[userDefaults objectForKey:@"harvestcookie"];
    
    NSLog(@"DEFAULTS\n: %@", cookie);
    if(!cookie){
        cookie = [self generateCookieData];
        [self setUserCookie:cookie];
    }
    NSLog(@"COOKIE\n: %@", cookie);
    return cookie;
}

-(void) setUserCookie: (NSDictionary *) cookie {
    
    if(!cookie){
        cookie = [self getUserCookie];
    }
    
    cookie = [[NSMutableDictionary alloc] initWithDictionary:cookie];
    [cookie setValue:[self getTimestamp] forKeyPath:@"lastSeen"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:cookie forKey:HARVEST_COOKIE];
    [userDefaults synchronize];
}

-(NSDictionary *) generateCookieData {
    NSDictionary *cookie = @{
                                @"$uuid": [Harvest generateUUID],
                                @"lastSeen": [self getTimestamp]
                            };
    return cookie;
}

-(void) track: (NSString *)event withData:(NSDictionary *) data {
    NSLog(@"track event");
    NSMutableDictionary *compiledData = [[NSMutableDictionary alloc] init];
    
    // merge in the include always data
    if(_includeData && [[_includeData allKeys] count] > 0){
        [compiledData addEntriesFromDictionary:_includeData];
    }
    
    // merge in the data passed
    if(data && [[data allKeys] count] > 0){
        [compiledData addEntriesFromDictionary:data];
    }
    
    // gather some information about the OS
    NSDictionary *deviceData = @{
                                    @"os": @"iOS",
                                    @"osVersion": [[UIDevice currentDevice] systemVersion],
                                    @"device": [[UIDevice currentDevice] model]
                                 };
    [compiledData setObject: deviceData forKey:@"device"];
    NSLog(@"%@", compiledData);
    
    _pretrack(event, compiledData, ^void(NSString *eventName, NSDictionary *data){
        NSLog(@"after pre track");
        
        NSMutableDictionary *compiledData = [[NSMutableDictionary alloc] initWithDictionary:data];

        [compiledData addEntriesFromDictionary:[self getUserCookie]];
        
        NSLog(@"%@", compiledData);
        NSLog(@"%@", data);
    });
}

-(void) identify:(NSString *)idToReplace {
    NSLog(@"identify user");
}

-(void) alwaysInclude:(NSDictionary *)data {
    _includeData = [[NSDictionary alloc] initWithDictionary:data];
}

// private methods

-(void) enqueue:(NSArray *)operation {
    
}

@end
