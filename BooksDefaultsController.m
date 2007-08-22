/// BooksDefaultsController.m

#include <math.h>

#import "BooksDefaultsController.h"

@implementation BooksDefaultsController

- (BooksDefaultsController *)init
{
  [super init];

  sharedDefaults = [[NSUserDefaults standardUserDefaults] retain];

  NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:5];

  [temp setObject:@"0" forKey:LASTSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:TOPVIEWKEY];
  [temp setObject:@"" forKey:FILEBEINGREADKEY];
  [temp setObject:@"16" forKey:TEXTSIZEKEY];
  [temp setObject:@"0" forKey:ISINVERTEDKEY];

  //  NSLog(@"temp dictionary: %@\n", temp);

  [sharedDefaults registerDefaults:temp];

  //  [sharedDefaults setInteger:TEXTVIEW forKey:TOPVIEWKEY];

  NSLog(@"defaults dump\n%d %d %@\n",
	[sharedDefaults integerForKey:LASTSCROLLPOINTKEY],
	[sharedDefaults integerForKey:TOPVIEWKEY],
	[sharedDefaults objectForKey:FILEBEINGREADKEY]);

  [temp release];
  return self;
}

- (unsigned int)lastScrollPoint
{
  return [sharedDefaults integerForKey:LASTSCROLLPOINTKEY];
}

- (int)topViewIndex
{
  return [sharedDefaults integerForKey:TOPVIEWKEY];
}

- (NSString *)fileBeingRead
{
  return [[sharedDefaults objectForKey:FILEBEINGREADKEY] autorelease];
}

- (int)textSize
{
  return [sharedDefaults integerForKey:TEXTSIZEKEY];
}

- (BOOL)inverted
{
  return [sharedDefaults boolForKey:ISINVERTEDKEY];
}

- (void)setLastScrollPoint:(unsigned int)point
{
  [sharedDefaults setInteger:point forKey:LASTSCROLLPOINTKEY];
}

- (void)setTopViewIndex:(int)index
{
  [sharedDefaults setInteger:index forKey:TOPVIEWKEY];
}

- (void)setFileBeingRead:(NSString *)file
{
  [sharedDefaults setObject:file forKey:FILEBEINGREADKEY];
}

- (void)setTextSize:(int)size
{
  [sharedDefaults setInteger:size forKey:TEXTSIZEKEY];
}

- (void)setInverted:(BOOL)isInverted
{
  [sharedDefaults setBool:isInverted forKey:ISINVERTEDKEY];
}

- (BOOL)synchronize
{
  return [sharedDefaults synchronize];
}

- (void)dealloc
{
  BOOL unused = [sharedDefaults synchronize];
  //  [fileBeingRead release];
  [sharedDefaults release];
  [super dealloc];
}


@end
