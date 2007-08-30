/// BooksDefaultsController.m

#import "BooksDefaultsController.h"

@implementation BooksDefaultsController

- (BooksDefaultsController *)init
{
  self = [super init];

  //  sharedDefaults = [[NSUserDefaults standardUserDefaults] retain];

  NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:14];

  [temp setObject:@"0" forKey:LASTSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:READINGTEXTKEY];
  [temp setObject:@"" forKey:FILEBEINGREADKEY];
  [temp setObject:@"16" forKey:TEXTSIZEKEY];
  [temp setObject:@"0" forKey:ISINVERTEDKEY];
  [temp setObject:EBOOK_PATH forKey:BROWSERFILESKEY];

  [temp setObject:@"TimesNewRoman" forKey:TEXTFONTKEY];
  [temp setObject:@"1" forKey:AUTOHIDE]; //CHANGED: Not used anymore. Autohide setting for each bar
  [temp setObject:@"1" forKey:NAVBAR];
  [temp setObject:@"1" forKey:TOOLBAR];
  [temp setObject:@"0" forKey:FLIPTOOLBAR];
  [temp setObject:@"1" forKey:CHAPTERNAV];
  [temp setObject:@"1" forKey:PAGENAV];
  [temp setObject:[NSMutableDictionary dictionaryWithCapacity:1] forKey:PERSISTENCEKEY];

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
  NSMutableDictionary *persistenceSanityCheck =
    [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  if (0 == [persistenceSanityCheck count])
    {
      NSLog(@"sanity check!");
      //This is here for backward compatibility with old persistence system
      NSString *file = [[NSUserDefaults standardUserDefaults] objectForKey:FILEBEINGREADKEY];
      int point = [[NSUserDefaults standardUserDefaults] integerForKey:LASTSCROLLPOINTKEY];
      float adjustedPoint = (float)point / [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
      NSString *pointString = [NSString stringWithFormat:@"%d", (int)adjustedPoint];
      [persistenceSanityCheck setObject:pointString forKey:file];

      [[NSUserDefaults standardUserDefaults] setObject:persistenceSanityCheck forKey:PERSISTENCEKEY];
    }

  //  NSLog(@"Persistence dictionary:\n%@", [[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]);
  return self;
}

- (unsigned int)lastScrollPoint
{
  return [[NSUserDefaults standardUserDefaults] integerForKey:LASTSCROLLPOINTKEY];
}

- (BOOL)scrollPointExistsForFile:(NSString *)filename
{
  NSDictionary *blah = [[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY];
  return (nil != [blah objectForKey:filename]);
}

- (unsigned int)lastScrollPointForFile:(NSString *)filename
  // Returns scroll point adjusted by the font size.
{
  NSDictionary *blah = [[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY];
  NSString *scrollpointString = [blah objectForKey:filename];
  if (nil == scrollpointString)
    return 0;
  else
    {
      int fontsize = [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
      // NSLog(@"scroll point: %d", (unsigned int)[scrollpointString intValue]);
      return (unsigned int)([scrollpointString intValue] * fontsize);
    }
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
  [[NSUserDefaults standardUserDefaults] setInteger:thePoint forKey:LASTSCROLLPOINTKEY];
}

- (void)setLastScrollPoint:(unsigned int)thePoint forFile:(NSString *)file
  // Adjusts the scroll point based on the font size.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  thePoint /= [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
  NSString *thePointString = [NSString stringWithFormat:@"%d", thePoint];
  [tempDict setObject:thePointString forKey:file];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
}

- (void)removeScrollPointForFile:(NSString *)file
  // Call this method when deleting a single text/HTML file from
  // the FileBrowser.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  [tempDict removeObjectForKey:file];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
}

- (void)removeScrollPointsForDirectory:(NSString *)dir
  // This method should be called when deleting a folder from the
  // FileBrowser, so the prefs file doesn't get crusty with deleted
  // books.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
					enumeratorAtPath:dir];
 if (nil != enumerator)
   {
     NSString *subpath;
     while (nil != (subpath = [enumerator nextObject]))
       {
	 [tempDict removeObjectForKey:[dir stringByAppendingPathComponent:subpath]];
       }
   }
 [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
 //phew!
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
  _toolbarShouldUpdate = YES;
}

- (void)setChapternav:(BOOL)isChpaternav
{
  [[NSUserDefaults standardUserDefaults] setBool:isChpaternav forKey:CHAPTERNAV];
  _toolbarShouldUpdate = YES;
}

- (void)setPagenav:(BOOL)isPagenav
{
  [[NSUserDefaults standardUserDefaults] setBool:isPagenav forKey:PAGENAV];
  _toolbarShouldUpdate = YES;
}

- (BOOL)synchronize
{
  if (_toolbarShouldUpdate) [[NSNotificationCenter defaultCenter] postNotificationName:@"toolbarDefaultsChanged" object:self];
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
