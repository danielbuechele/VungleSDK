//
//  VGAnalytics.m
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//

#import "VGAnalytics.h"
#import "sbjson/VGSBJson.h"
#import "VGDownload.h"
#include <netinet/in.h>
#import "SystemConfiguration/SCNetworkReachability.h"

@interface VGAnalytics ()
@property(nonatomic,retain) NSString *appId;
@property(nonatomic,retain) NSString* analyticsURL;
@property(nonatomic,assign) BOOL sendOnBackground;
@property(nonatomic,assign) NSUInteger uploadInterval;
//@property(nonatomic,retain) NSMutableDictionary *userProperties;
@property(nonatomic,retain) NSArray *actions;
@property(nonatomic,retain) NSMutableArray *allActions;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,retain) NSMutableData *responseData;

-(void)start;
-(void)endBackgroundTask;
-(void)sendData;
-(NSString*)filePath;
-(void)readSavedData;
-(void)saveData;
-(void)applicationWillTerminate:(NSNotification *)notification;
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification;
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification;
-(void)setHeadersforRequest:(NSMutableURLRequest*)request;
@end

static NSString* VGContentJSON = @"application/json";
static NSString* VGContentType = @"Content-Type";

@implementation VGAnalytics
@synthesize appId, sendOnBackground, connection, delegate; //userProperties has been removed since we dont need it
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
        //userProperties = [[NSMutableDictionary alloc] init];
        sendOnBackground = YES;
        analyticsURL = @"http://localhost:3000/api/v1/analytics";
        uploadInterval = kVGInterval;
        //[self.userProperties setObject:@"iOS" forKey:@"platform"];
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

-(void)trackAction:(NSString *)act
{
    NSMutableDictionary *temp = [[[NSMutableDictionary alloc] init] autorelease];
    [temp setObject:act forKey:@"action"];
    NSDate *x = [[NSDate alloc] init];
    NSTimeInterval y = [x timeIntervalSince1970];
    [temp setValue:[NSNumber numberWithDouble:y] forKey:@"eventtime"];
    [x release];
    [allActions addObject:temp];
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
    if ([self.allActions count] == 0 || self.connection != nil) { // No events or already pushing data.
		return;
	} else if ([self.allActions count] > 50) {
		self.actions = [self.allActions subarrayWithRange:NSMakeRange(0, 50)];
	} else {
		self.actions = [NSArray arrayWithArray:self.allActions];
	}
    
    VGJsonWriter *writer = [[VGJsonWriter alloc] init];
    
    NSLog(@"ACt %@", actions);//TEST ONLY
    
    NSDictionary *postData = [[NSDictionary alloc] initWithObjectsAndKeys:[self findReachability],@"connection",[VGDownload getOpenUDID],@"isu",self.appId,@"pubAppId",actions,@"actions", nil];
    
    NSString *data;
    
    if(NSClassFromString(@"NSJSONSerialization")) {
        NSData *tempdata = [NSJSONSerialization dataWithJSONObject:postData options:0 error:nil];
        data = [[NSString alloc] initWithData:tempdata encoding:NSUTF8StringEncoding];
        [data autorelease];
        NSLog(@"hello world");//TEST ONLY
    }
    else {
        data = [writer stringWithObject:postData];
    }
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSString *postBody = [NSString stringWithFormat:@"%@", data];
    
    NSLog(@"%@",postBody);//TEST ONLY
    
	NSURL *url = [NSURL URLWithString:analyticsURL];//vungle endpoint here
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[request release];
    [postData release];
    [writer release];
}

-(void)setHeadersforRequest:(NSMutableURLRequest*)request
{
    [request setValue:VGContentJSON forHTTPHeaderField:VGContentType];
}

-(void)readSavedData
{
    NSLog(@"reading data %@", self.allActions);
    self.allActions = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath]];
	if (!self.allActions) {
		self.allActions = [NSMutableArray array];
	}
}
-(void)saveData
{
    NSLog(@"saving data %@", self.allActions);
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
	NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];

    NSLog(@"%@", response);//TEST ONLY
    
    VGJsonParser *parser = [[VGJsonParser alloc] init];
    NSDictionary *dict;
    
    if(NSClassFromString(@"NSJSONSerialization")) {
        dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        NSLog(@"hello world");//TEST ONLY
    }
    else {
        dict = [parser objectWithData:responseData];
    }
    
    NSLog(@"DICTIONARY %@", dict);//TEST ONLY
    
    [self.allActions removeObjectsInArray:self.actions];
    
	[self saveData];
	self.actions = nil;
    self.connection = nil;
	self.responseData = nil;
    [response release];
    [parser release];
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
        }];
        [self sendData];
    } else {
        [self saveData];
    }
}

//timer code
- (void) setUploadInterval:(NSUInteger) newInterval {
    uploadInterval = newInterval;
    
    if (timer) {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    
    [self sendData];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:uploadInterval
                                             target:self
                                           selector:@selector(sendData)
                                           userInfo:nil
                                            repeats:YES];
    [timer retain];
}

- (void) stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [timer invalidate];
    [timer release];
    timer = nil;
    [self saveData];
}

- (void)dealloc
{
    [self saveData];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [appId release];
    [actions release];
    //[userProperties release];
    [timer invalidate];
    [timer release];
    [allActions release];
    [responseData release];
    [connection release];
    [super dealloc];
}

@end
