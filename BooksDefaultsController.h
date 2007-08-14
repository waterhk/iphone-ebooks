/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface BooksDefaultsController : NSObject
{

  struct CGPoint lastScrollPoint;
  int topViewIndex;
  NSString *fileBeingRead;

  NSUserDefaults *sharedDefaults;
}

#define LASTXSCROLLPOINTKEY @"lastXScrollPointKey"
#define LASTYSCROLLPOINTKEY @"lastYScrollPointKey"
#define TOPVIEWKEY @"topViewKey"
#define FILEBEINGREADKEY @"fileBeingReadKey"

#define BROWSERVIEW 0
#define CHAPTERBROWSERVIEW 1
#define TEXTVIEW 2

- (struct CGPoint)lastScrollPoint;
- (int)topViewIndex;
- (NSString *)fileBeingRead;

- (void)setLastScrollPoint:(struct CGPoint)point;
- (void)setTopViewIndex:(int)index;
- (void)setFileBeingRead:(NSString *)file;

- (BOOL)synchronize;

@end

