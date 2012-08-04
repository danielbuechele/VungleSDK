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
//for mac address
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import <CommonCrypto/CommonHMAC.h>


@interface VGAnalytics ()
@property(nonatomic,retain) NSString *appId;
@property(nonatomic,retain) NSString *secretKey;
@property(nonatomic,retain) NSString* analyticsURL;
@property(nonatomic,retain) NSString* macAddress;
@property(nonatomic,assign) BOOL sendOnBackground;
@property(nonatomic,assign) NSUInteger uploadInterval;
@property(nonatomic,retain) NSArray *actions;
@property(nonatomic,retain) NSMutableArray *allActions;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,retain) NSMutableData *responseData;

-(void)start;
-(void)endBackgroundTask;
-(void)sendData;
-(NSString*)filePath;
-(NSString*)VGMACAddress;
-(NSTimeInterval)VGCurrentTime;
-(void)readSavedData;
-(void)saveData;
-(void)applicationWillTerminate:(NSNotification *)notification;
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification;
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification;
-(void)setHeadersforRequest:(NSMutableURLRequest*)request;
-(void)trackSession;
@end

static NSString* VGContentJSON = @"application/json";
static NSString* VGContentType = @"Content-Type";
static NSTimeInterval startin  = 0;

static NSString* VGcalculateHMAC_SHA256(NSString *str, NSString *key) {
	const char *cStr = [str UTF8String];
	const char *cSecretStr = [key UTF8String];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA256, cSecretStr, strlen(cSecretStr), cStr, strlen(cStr), digest);
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			digest[0],  digest[1],  digest[2],  digest[3],
			digest[4],  digest[5],  digest[6],  digest[7],
			digest[8],  digest[9],  digest[10], digest[11],
			digest[12], digest[13], digest[14], digest[15],
			digest[16], digest[17], digest[18], digest[19],
            digest[20], digest[21], digest[22], digest[23],
            digest[24], digest[25], digest[26], digest[27],
            digest[28], digest[29], digest[30], digest[31]
			];
}

@implementation VGAnalytics
@synthesize appId, sendOnBackground, connection, delegate;
@synthesize analyticsURL, responseData, uploadInterval, actions, allActions;

static VGAnalytics *sharedInstance = nil;

-(NSTimeInterval)VGCurrentTime
{
    NSDate*               date = [[NSDate alloc] init];
    const NSTimeInterval  tval = [date timeIntervalSince1970];
    
    [date release];
    date = nil;
    return tval;
}

-(NSString*)getVersion
{
    return @"0.9";
}

-(NSString*)getiOSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (id)initWithAppId:(NSString *)AppId andSecretKey:(NSString *)secret
{
    if (AppId == nil || secret == nil)
    {
        return nil;
    }
    if ((self = [self init])) {
        self.appId = AppId;
        self.secretKey = secret;
        [self start];
    }
    return  self;
}

-(NSString*)VGMACAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    NSString            *errorFlag = NULL;
    size_t              length;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0) {
        errorFlag = @"if_nametoindex failure";
    }
    // Get the size of the data available (store in len)
    else if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0) {
        errorFlag = @"sysctl mgmtInfoBase failure";
    }
    // Alloc memory based on above call
    else if ((msgBuffer = malloc(length)) == NULL) {
        errorFlag = @"buffer allocation failure";
    }
    // Get system information, store in buffer
    else if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0) {
        free(msgBuffer);
        errorFlag = @"sysctl msgBuffer failure";
    }
    else {
        // Map msgbuffer to interface message structure
        struct if_msghdr *interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
        
        // Map to link-level socket structure
        struct sockaddr_dl *socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
        
        // Copy link layer address data in socket structure to an array
        unsigned char macAddress[6];
        memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        
        // Read from char array into a string object, into traditional Mac address format
        NSString *macAddressString = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X",
                                      macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]];
        
        // Release the buffer memory
        free(msgBuffer);
        
        return [macAddressString lowercaseString];
    }
    
    // Error...
    NSLog(@"Error: %@", errorFlag);
    
    return nil;
}

- (id)init
{
    if ((self = [super init])) {
       actions = [[NSMutableArray alloc] init];
       sendOnBackground = YES;
       analyticsURL = @"http://acceptance.vungle.com/api/v1/analytics";
       uploadInterval = kVGInterval;
       userName = nil;
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
    startin = [self VGCurrentTime]; 
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

-(void)trackSession
{
    NSString *sess = @"VGSession";
    NSMutableDictionary *temp = [[[NSMutableDictionary alloc] init] autorelease];
    [temp setObject:sess forKey:@"action"];
    [temp setValue:[NSNumber numberWithDouble:startin] forKey:@"starttime"];
    [temp setValue:[NSNumber numberWithDouble:[self VGCurrentTime]] forKey:@"endtime"];
    [allActions addObject:temp];
}

-(void)setUsername:(NSString *)user
{
    userName = user;
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
    if(self.macAddress == nil)
    {
        self.macAddress = [self VGMACAddress];
    }
    if ([self.allActions count] == 0 || self.connection != nil) { // No events or already pushing data.
        return;        
	} else if ([self.allActions count] > 50) {
		self.actions = [self.allActions subarrayWithRange:NSMakeRange(0, 50)];
	} else {
		self.actions = [NSArray arrayWithArray:self.allActions];
	}
    
    VGJsonWriter *writer = [[VGJsonWriter alloc] init];
    NSTimeInterval x = [self VGCurrentTime];
    NSString *sendTime = [[NSNumber numberWithLong:x] stringValue];
    NSString *authorization = VGcalculateHMAC_SHA256(self.secretKey, sendTime);
    
    NSMutableDictionary *postData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self findReachability],@"connection",[VGDownload getOpenUDID],@"isu",self.appId,@"appId",actions,@"actions", self.macAddress , @"mac", [self getiOSVersion], @"iOSVersion", [self getVersion], @"x-vungle-version", sendTime, @"sendTime", authorization, @"authorization", nil];
    
    if(userName != nil)
    {
        [postData setObject:userName forKey:@"username"];
    }
    
    NSString *data;
    
    if(NSClassFromString(@"NSJSONSerialization")) {
        NSData *tempdata = [NSJSONSerialization dataWithJSONObject:postData options:0 error:nil];
        data = [[NSString alloc] initWithData:tempdata encoding:NSUTF8StringEncoding];
        [data autorelease];
    }
    else {
        data = [writer stringWithObject:postData];
    }
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSString *postBody = [NSString stringWithFormat:@"%@", data];
        
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
    if(self.responseData == nil)
    {
        self.actions = nil;
        self.connection = nil;
        [self saveData];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self endBackgroundTask];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(VGAnalytics:didUploadActions:)]) {
        [self.delegate VGAnalytics:self didUploadActions:self.actions];
        
    }
    
	NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];

    VGJsonParser *parser = [[VGJsonParser alloc] init];
    NSDictionary *dict = nil;
    
    if(NSClassFromString(@"NSJSONSerialization")&&self.responseData!=nil) {
        dict = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:nil];
    }
    else {
        dict = [parser objectWithData:responseData];
    }
    
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
    [self trackSession];
    [self saveData];
}
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{
    if (self.appId) {
		[self readSavedData];
		[self sendData];
	}
    startin = [self VGCurrentTime];
    [self endBackgroundTask];
}
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification
{
    [self trackSession];
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
    if(userName!=nil) {
        [userName release];
    }
    [timer invalidate];
    [timer release];
    [allActions release];
    [responseData release];
    [connection release];
    [super dealloc];
}

@end
