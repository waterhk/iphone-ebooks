/// BooksDefaultsController.m

#include <math.h>

#import "BooksDefaultsController.h"

@implementation BooksDefaultsController

- (BooksDefaultsController *)init
{
  [super init];

  sharedDefaults = [[NSUserDefaults standardUserDefaults] retain];

  NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:4];

  [temp setObject:@"0" forKey:LASTXSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:LASTYSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:TOPVIEWKEY];
  [temp setObject:@"" forKey:FILEBEINGREADKEY];

  NSLog(@"temp dictionary: %@\n", temp);

  [sharedDefaults registerDefaults:temp];

  //  [sharedDefaults setInteger:TEXTVIEW forKey:TOPVIEWKEY];

  NSLog(@"defaults dump\n%d %d %d %@\n",
	[sharedDefaults integerForKey:LASTXSCROLLPOINTKEY],
	[sharedDefaults integerForKey:LASTYSCROLLPOINTKEY],
	[sharedDefaults integerForKey:TOPVIEWKEY],
	[sharedDefaults objectForKey:FILEBEINGREADKEY]);

  return self;
}

- (struct CGPoint)lastScrollPoint
{
  struct CGPoint ret;
  ret = CGPointMake([sharedDefaults integerForKey:LASTXSCROLLPOINTKEY],
		    [sharedDefaults integerForKey:LASTYSCROLLPOINTKEY]);
  return ret;
}

- (int)topViewIndex
{
  return [sharedDefaults integerForKey:TOPVIEWKEY];
}

- (NSString *)fileBeingRead
{
  return [[sharedDefaults objectForKey:FILEBEINGREADKEY] autorelease];
}

- (void)setLastScrollPoint:(struct CGPoint)point
{
  [sharedDefaults setFloat:point.x forKey:LASTXSCROLLPOINTKEY];
  [sharedDefaults setFloat:point.y forKey:LASTYSCROLLPOINTKEY];

  NSLog(@"x: %f y: %f\n", point.x, point.y);
  NSLog(@"objectx:%@ objecty:%@", [sharedDefaults objectForKey:LASTXSCROLLPOINTKEY], [sharedDefaults objectForKey:LASTYSCROLLPOINTKEY]);
}

- (void)setTopViewIndex:(int)index
{
  [sharedDefaults setInteger:index forKey:TOPVIEWKEY];
}

- (void)setFileBeingRead:(NSString *)file
{
  [sharedDefaults setObject:file forKey:FILEBEINGREADKEY];
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
