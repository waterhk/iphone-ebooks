/// BooksDefaultsController.m

#import "BooksDefaultsController.h"

@implementation BooksDefaultsController

- (BooksDefaultsController *)init
{
  self = [super init];

  //  sharedDefaults = [[NSUserDefaults standardUserDefaults] retain];

  NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:10];

  [temp setObject:@"0" forKey:LASTSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:READINGTEXTKEY];
  [temp setObject:@"" forKey:FILEBEINGREADKEY];
  [temp setObject:@"16" forKey:TEXTSIZEKEY];
  [temp setObject:@"0" forKey:ISINVERTEDKEY];
  [temp setObject:EBOOK_PATH forKey:BROWSERFILESKEY];
 
  [temp setObject:@"TimesNewRoman" forKey:TEXTFONTKEY];
  [temp setObject:@"1" forKey:AUTOHIDE];
  [temp setObject:@"1" forKey:NAVBAR];
  [temp setObject:@"1" forKey:TOOLBAR];
  [temp setObject:@"0" forKey:FLIPTOOLBAR];
  [temp setObject:@"1" forKey:CHAPTERNAV];
  [temp setObject:@"1" forKey:PAGENAV];

  //  NSLog(@"temp dictionary: %@\n", temp);

  [[NSUserDefaults standardUserDefaults] registerDefaults:temp];
  /*
    NSLog(@"defaults dump\n%d %d %@\n%@\n",
  	[sharedDefaults integerForKey:LASTSCROLLPOINTKEY],
  	[sharedDefaults integerForKey:TEXTSIZEKEY],
  	[sharedDefaults objectForKey:FILEBEINGREADKEY],
	  [sharedDefaults objectForKey:BROWSERFILESKEY]);
  */
  [temp release];
  return self;
}

- (unsigned int)lastScrollPoint
{
  return [[NSUserDefaults standardUserDefaults] integerForKey:LASTSCROLLPOINTKEY];
}

- (NSString *)fileBeingRead
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:FILEBEINGREADKEY];
}

- (int)textSize
{
  return [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
}

- (BOOL)inverted
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:ISINVERTEDKEY];
}

- (BOOL)readingText
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:READINGTEXTKEY];
}

- (NSString *)lastBrowserPath
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:BROWSERFILESKEY];
}

- (void)setLastScrollPoint:(unsigned int)thePoint
{
  NSLog(@"in");
  [[NSUserDefaults standardUserDefaults] setInteger:thePoint forKey:LASTSCROLLPOINTKEY];
  NSLog(@"out");
}

- (void)setLastBrowserPath:(NSString *)browserPath
{
  [[NSUserDefaults standardUserDefaults] setObject:browserPath forKey:BROWSERFILESKEY];
}

- (void)setFileBeingRead:(NSString *)file
{
  [[NSUserDefaults standardUserDefaults] setObject:file forKey:FILEBEINGREADKEY];
}

- (void)setTextSize:(int)size
{
  [[NSUserDefaults standardUserDefaults] setInteger:size forKey:TEXTSIZEKEY];
}

- (void)setInverted:(BOOL)isInverted
{
  [[NSUserDefaults standardUserDefaults] setBool:isInverted forKey:ISINVERTEDKEY];
}

- (void)setReadingText:(BOOL)readingText
{
  [[NSUserDefaults standardUserDefaults] setBool:readingText forKey:READINGTEXTKEY];
}

- (void)setTextFont:(NSString *)font
{
  [[NSUserDefaults standardUserDefaults] setObject:font forKey:TEXTFONTKEY];
}

- (NSString *)textFont
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:TEXTFONTKEY];
}

- (BOOL)autohide
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:AUTOHIDE];
}

- (BOOL)navbar
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:NAVBAR];
}

- (BOOL)toolbar
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:TOOLBAR];
}

- (BOOL)flipped
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:FLIPTOOLBAR];
}

- (BOOL)chapternav
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:CHAPTERNAV];
}

- (BOOL)pagenav
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:PAGENAV];
}

- (void)setAutohide:(BOOL)isAutohide
{
  [[NSUserDefaults standardUserDefaults] setBool:isAutohide forKey:AUTOHIDE];
}

- (void)setNavbar:(BOOL)isNavbar
{
  [[NSUserDefaults standardUserDefaults] setBool:isNavbar forKey:NAVBAR];
}

- (void)setToolbar:(BOOL)isToolbar
{
  [[NSUserDefaults standardUserDefaults] setBool:isToolbar forKey:TOOLBAR];
}

- (void)setFlipped:(BOOL)isFlipped
{
  [[NSUserDefaults standardUserDefaults] setBool:isFlipped forKey:FLIPTOOLBAR];
}

- (void)setChapternav:(BOOL)isChpaternav
{
  [[NSUserDefaults standardUserDefaults] setBool:isChpaternav forKey:CHAPTERNAV];
}

- (void)setPagenav:(BOOL)isPagenav
{
  [[NSUserDefaults standardUserDefaults] setBool:isPagenav forKey:PAGENAV];
}

- (BOOL)synchronize
{
  return [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
  BOOL unused = [[NSUserDefaults standardUserDefaults] synchronize];
  //  [fileBeingRead release];
  //  [sharedDefaults release];
  [super dealloc];
}


@end
