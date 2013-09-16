// MainViewController.m -- main view controller for test app
// by allen brunson  january 9 2012

#import "AppDelegate.h"
#import "MainView.h"
#import "MainViewController.h"
#import "Prefs.h"

@implementation MainViewController

@synthesize mainView;

-(void)buttonPlayAd:(id)sender
{
    if ([Prefs getIncentivized]) {
        [VGVunglePub playIncentivizedAd:self animated:TRUE showClose:TRUE userTag:@"helloworld"];
    }
    else {
        [VGVunglePub playModalAd:self animated:TRUE];
    }
	[_player stop];
}

-(void)buttonPrefs:(id)sender
{
    [AppDelegate runPrefs];
}

+(MainViewController*)controller
{
    return [[[self alloc] initWithNibName:nil bundle:nil] autorelease];
}

-(void)dealloc
{
    self.mainView = nil;
    
    [super dealloc];
}

-(id)initWithNibName:(NSString*)nibName bundle:(NSBundle*)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];
    if (!self) return nil;
    
    self.title = @"Vungle Test";
    
    return self;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orient
{
    return TRUE;
}

-(void)terminalClear
{
    [self.mainView terminalClear];
}

-(void)viewDidLoad
{
    SEL  prc1 = @selector(buttonPlayAd:);
    SEL  prc2 = @selector(buttonPrefs:);
    
    [super viewDidLoad];
    
    [self setMainView:[MainView view]];
    [self setView:self.mainView];
    
    [self.mainView.playButton addButtonTarget:self action:prc1];
    [self.mainView.prefsButton addButtonTarget:self action:prc2];
	
	// start playing background music
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *filePath = [mainBundle pathForResource:@"Music" ofType:@"mp3"];
	NSData *fileData = [NSData dataWithContentsOfFile:filePath];
	NSError *error = nil;
	
	_player = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
	[_player play];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    [self setMainView:nil];
    
    nlog(@"%@ unloaded", self.className);
}

-(void)vungleLogLine:(NSString*)logLine
{
    [self.mainView vungleLogLine:logLine];
}

-(void)vungleMoviePlayed:(VGPlayData*)playData
{
    // movie ad finished, get times from playData
}

-(void)vungleViewDidDisappear:(UIViewController*)viewController
{
    // ad view is gone, resume music
	[_player play];
}

-(void)vungleViewWillAppear:(UIViewController*)viewController
{
    // ad view will appear
}

-(void)vungleStatusUpdate:(VGStatusData*)statusData
{
    [self.mainView vungleStatusUpdate:statusData];
}

-(void)vungleAppStoreViewDidDisappear
{
    // vungle app store view disappeared
    nlog(@"App Store View closed");
}

@end
