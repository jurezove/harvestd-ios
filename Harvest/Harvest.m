//
//  Harvest.m
//  Harvest
//
//  Created by Sean McGary on 8/20/14.
//  Copyright (c) 2014 Sean McGary. All rights reserved.
//

#import "Harvest.h"

#define HARVEST_COOKIE @"harvestcookie"
#define HARVEST_ACTION_PATH @"/actions"

@interface Harvest()

-(void) enqueue: (NSArray *) action;
-(void) sendData: (NSArray *) actions;
-(void) processQueue;

@property (strong, nonatomic) NSMutableArray *queue;

@end

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
    return [[NSUUID UUID] UUIDString];
}

// static methods


-(id) init {
    self = [super init];
    
    if(self){
        _includeData = @{};
        _dispatchQueue = dispatch_queue_create("harvestqueue", NULL);
        _queue = [[NSMutableArray alloc] init];
    }
    
    _pretrack = ^void (NSString * eventName, NSDictionary *data, void(^cb)(NSString *, NSDictionary *)){
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


-(NSDictionary *) getUserCookie {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *cookie = (NSDictionary *)[userDefaults objectForKey:@"harvestcookie"];
    
    if(!cookie){
        cookie = [self generateCookieData];
        [self setUserCookie:cookie];
    }
    return cookie;
}

-(void) setUserCookie: (NSDictionary *) cookie {
    
    if(!cookie){
        cookie = [self getUserCookie];
    }
    
    cookie = [[NSMutableDictionary alloc] initWithDictionary:cookie];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:cookie forKey:HARVEST_COOKIE];
    [userDefaults synchronize];
}

-(NSDictionary *) generateCookieData {
    NSDictionary *cookie = @{
                                @"$uuid": [Harvest generateUUID]
                            };
    return cookie;
}

-(void) track: (NSString *)event withData:(NSDictionary *) data {
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
    
    _pretrack(event, compiledData, ^void(NSString *eventName, NSDictionary *data){
        
        NSMutableDictionary *compiledData = [[NSMutableDictionary alloc] initWithDictionary:data];

        [compiledData addEntriesFromDictionary:[self getUserCookie]];
        
        [self enqueue:@[@"track", @{
                            @"event": event,
                            @"data": compiledData,
                            @"token": _apiToken
                        }]];
    });
}

-(void) identify:(NSString *) idToReplace {
    NSLog(@"identify user");
    
    if(!idToReplace || [idToReplace length] == 0){
        NSLog(@"please provide an id");
        return;
    }
    
    NSDictionary *cookie = [self getUserCookie];
    NSDictionary *payload = @{
                                @"token": _apiToken,
                                @"uuid": [cookie objectForKey:@"$uuid"],
                                @"userId": idToReplace
                              };
    NSLog(@"payload:\n%@", payload);
    [self enqueue:@[@"identify", payload]];
}

-(void) alwaysInclude:(NSDictionary *)data {
    _includeData = [[NSDictionary alloc] initWithDictionary:data];
}

// private
-(void) enqueue: (NSArray *) action {
    [_queue addObject:action];
    
    [self processQueue];
}

-(void) processQueue {
    dispatch_async(_dispatchQueue, ^{
        if([[self queue] count] > 0){
            // sleep for 200ms to allow the queue to fill up
            [NSThread sleepForTimeInterval:0.2];
        
            NSArray *sendActions = [[NSArray alloc] initWithArray:[[self queue] copy]];
        
            _queue = @[];
            
            [self sendData:sendActions];
        }
    });
}

-(void) sendData:(NSArray *)actions {
    if(!_hostname || [_hostname length] == 0){
        NSLog(@"Missing hostname");
        return;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", [self hostname], HARVEST_ACTION_PATH];
    
    NSDictionary *jsonData = @{@"actions": actions};
    
    [manager POST:path parameters:jsonData success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
