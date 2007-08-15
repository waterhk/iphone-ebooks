/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface BooksDefaultsController : NSObject
{

  unsigned int lastScrollPoint;
  int topViewIndex;
  NSString *fileBeingRead;

  NSUserDefaults *sharedDefaults;
}

#define LASTSCROLLPOINTKEY @"lastScrollPointKey"
#define TOPVIEWKEY @"topViewKey"
#define FILEBEINGREADKEY @"fileBeingReadKey"

#define BROWSERVIEW 0
#define CHAPTERBROWSERVIEW 1
#define TEXTVIEW 2

- (unsigned int)lastScrollPoint;
- (int)topViewIndex;
- (NSString *)fileBeingRead;

- (void)setLastScrollPoint:(unsigned int)point;
- (void)setTopViewIndex:(int)index;
- (void)setFileBeingRead:(NSString *)file;

- (BOOL)synchronize;

@end

