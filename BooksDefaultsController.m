/// BooksDefaultsController.m

#include <math.h>

#import "BooksDefaultsController.h"

@implementation BooksDefaultsController

- (BooksDefaultsController *)init
{
  [super init];

  sharedDefaults = [[NSUserDefaults standardUserDefaults] retain];

  NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:4];

  [temp setObject:@"0" forKey:LASTSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:TOPVIEWKEY];
  [temp setObject:@"" forKey:FILEBEINGREADKEY];
  [temp setObject:@"16" forKey:TEXTSIZEKEY];

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
