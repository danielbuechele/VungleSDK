//
//  VGAnalytics.m
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//  Copyright (c) 2012 Carnegie Mellon University. All rights reserved.
//

#import "VGAnalytics.h"
#import "VGDownload.h"
#include <netinet/in.h>
#import "SystemConfiguration/SCNetworkReachability.h"

@interface VGAnalytics ()
@property(nonatomic,retain) NSString *appId;
@property(nonatomic,retain) NSString* analyticsURL;
@property(nonatomic,assign) BOOL sendOnBackground;
@property(nonatomic,assign) NSUInteger uploadInterval;
@property(nonatomic,retain) NSMutableDictionary *userProperties;
@property(nonatomic,retain) NSArray *actions;
@property(nonatomic,retain) NSMutableArray *allActions;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,retain) NSMutableData *responseData;
@property(nonatomic,retain) id<VGAnalyticsDelegate> delegate;

-(void)start;
-(void)endBackgroundTask;
//-(void)sendData;
-(NSString*)filePath;
-(void)readSavedData;
-(void)saveData;
-(void)applicationWillTerminate:(NSNotification *)notification;
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification;
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification;
@end

static NSString* VGContentJSON = @"application/json";
static NSString* VGContentType = @"Content-Type";

@implementation VGAnalytics
@synthesize appId, sendOnBackground, userProperties, connection, delegate;
@synthesize analyticsURL, responseData, uploadInterval, actions, allActions;

static VGAnalytics *sharedInstance = nil;

-(NSString*)getVersion
{
    return @"0.1";
}

-(NSString*)getiOSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (id)initWithAppId:(NSString *)AppId
{
    if ((self = [self init])) {
        self.appId = AppId;
        [self start];
    }
    return  self;
}
- (id)init
{
   if ((self = [super init])) {
        actions = [[NSMutableArray alloc] init];
        userProperties = [[NSMutableDictionary alloc] init];
        sendOnBackground = YES;
        analyticsURL = @"blahblah";
        uploadInterval = kVGInterval;
        [self.userProperties setObject:@"iOS" forKey:@"platform"];
    }
    
    return self;
}

+(id)sharedTool
{
    return sharedInstance;
}

- (NSString*) filePath 
{
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VGAnalytics.plist"];
}

- (void) start {
    sharedInstance = self;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && &UIBackgroundTaskInvalid) {
        
        taskIdentCard = UIBackgroundTaskInvalid;
        if (&UIApplicationDidEnterBackgroundNotification) {
            [notificationCenter addObserver:self 
                                   selector:@selector(applicationDidEnterBackground:) 
                                       name:UIApplicationDidEnterBackgroundNotification 
                                     object:nil];
        }
        if (&UIApplicationWillEnterForegroundNotification) {
            [notificationCenter addObserver:self 
                                   selector:@selector(applicationWillEnterForeground:) 
                                       name:UIApplicationWillEnterForegroundNotification 
                                     object:nil];
        }
    }

    [notificationCenter addObserver:self 
                           selector:@selector(applicationWillTerminate:) 
                               name:UIApplicationWillTerminateNotification 
                             object:nil];
    
    [self readSavedData];
    [self sendData];
    [self setUploadInterval:uploadInterval];
}

-(NSString*)findReachability
{
    SCNetworkReachabilityFlags flags = 0;
    static SCNetworkReachabilityRef sReach;
    struct sockaddr_in  addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(0);
    addr.sin_port        = htons(0);
    const struct sockaddr_in  sock = addr;
    const struct sockaddr*    sptr = (const struct sockaddr*) &sock;
    
    sReach = SCNetworkReachabilityCreateWithAddress(NULL, sptr);
    SCNetworkReachabilityGetFlags(sReach, &flags);
    if (sReach) {
        CFRelease(sReach);        
    }
    if (!(flags & kSCNetworkFlagsReachable)) return @"offline";
    
    if (flags & kSCNetworkFlagsInterventionRequired) return @"offline";
    
    if (flags & kSCNetworkReachabilityFlagsIsWWAN)
    {
        return @"wwan";
    }
    else
    {
        return @"wifi";
    }
}

-(void)sendData
{
    [allActions addObject:[NSDictionary dictionaryWithObject:@"TRUE" forKey:@"SEXYTIME"]];
    if ([self.allActions count] == 0 || self.connection != nil) { // No events or already pushing data.
		//return;
	} else if ([self.allActions count] > 50) {
		self.actions = [self.allActions subarrayWithRange:NSMakeRange(0, 50)];
	} else {
		self.actions = [NSArray arrayWithArray:self.allActions];
	}
    
	//NSLog(@"er %@",[allActions valueForKey:@"dictionaryValue"]);
    
    NSLog(@"ACt %@", actions);
    
    NSDictionary *postData = [[NSDictionary alloc] initWithObjectsAndKeys:[self findReachability],@"connection",[VGDownload getOpenUDID],@"isu",self.appId,@"pubAppId",actions,@"actions", nil];
    
	NSData *data = [NSJSONSerialization dataWithJSONObject:postData options:0 error:nil];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSString *postBody = [NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    
    NSLog(@"%@",postBody);
    
//	NSURL *url = [NSURL URLWithString:@""];//vungle endpoint here
//	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
//	[request setValue:VGContentJSON forHTTPHeaderField:VGContentType];
//	[request setHTTPMethod:@"POST"];
//	[request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
//	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
//	[request release];
}
-(void)readSavedData
{
    self.allActions = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath]];
	if (!self.allActions) {
		self.allActions = [NSMutableArray array];
	}
}
-(void)saveData
{
    if (![NSKeyedArchiver archiveRootObject:[self allActions] toFile:[self filePath]]) {
		NSLog(@"Unable to archive data!!!");
	}
}

#pragma mark -
#pragma mark NSURLConnection Callbacks
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	if ([response statusCode] != 200) {
		NSLog(@"fail %@", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]);
	} else {
		self.responseData = [NSMutableData data];
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	[self.responseData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
	NSLog(@"error, clean up %@", error);
    if ([self.delegate respondsToSelector:@selector(VGAnalytics:didFailToUploadActions:withError:)]) {
        [self.delegate VGAnalytics:self didFailToUploadActions:self.actions withError:error];
    }
	self.actions = nil;
	self.responseData = nil;
	self.connection = nil;
    [self saveData];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	[self endBackgroundTask];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    if ([self.delegate respondsToSelector:@selector(VGAnalytics:didUploadActions:)]) {
        [self.delegate VGAnalytics:self didUploadActions:self.actions];
        
    }
	//NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
	//NSInteger result = [response intValue];
    
    [self.allActions removeObjectsInArray:self.actions];
	
    //if (result == 0) {
	//	NSLog(@"failed %@", response);
	//}
    
    //[response release];
	[self saveData];
	self.actions = nil;
	self.responseData = nil;
	self.connection = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	[self endBackgroundTask];
}

-(void)endBackgroundTask;
{
    if (&UIBackgroundTaskInvalid && [[UIApplication sharedApplication] respondsToSelector:@selector(endBackgroundTask:)] && taskIdentCard != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:taskIdentCard];
        taskIdentCard = UIBackgroundTaskInvalid;
	}
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    [self saveData];
}
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{
    if (self.appId) {
		[self readSavedData];
		[self sendData];
	}
    
    [self endBackgroundTask];

}
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)] &&
        [[UIApplication sharedApplication] respondsToSelector:@selector(endBackgroundTask:)]) {
        taskIdentCard = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self.connection cancel];
            self.connection = nil;
            [self saveData];
            [[UIApplication sharedApplication] endBackgroundTask:taskIdentCard];
            taskIdentCard = UIBackgroundTaskInvalid;
        }]	;
        [self sendData];
    } else {
        [self saveData];
    }
}

- (void) stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[timer invalidate];
    //[timer release];
    //timer = nil;
    [self saveData];
}

- (void)dealloc
{
    [self saveData];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [appId release];
    [actions release];
    [userProperties release];
    //[timer invalidate];
    //[timer release];
    [allActions release];
    [responseData release];
    [connection release];
    //[userId release];
    [super dealloc];
}

@end
