/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface BooksDefaultsController : NSObject
{

  unsigned int lastScrollPoint;
  int topViewIndex;
  NSString *fileBeingRead;
  int textSize;

  NSUserDefaults *sharedDefaults;
}

#define LASTSCROLLPOINTKEY @"lastScrollPointKey"
#define TOPVIEWKEY @"topViewKey"
#define FILEBEINGREADKEY @"fileBeingReadKey"
#define TEXTSIZEKEY @"textSizeKey"
#define ISINVERTEDKEY @"isInvertedKey"

#define BROWSERVIEW 0
#define CHAPTERBROWSERVIEW 1
#define TEXTVIEW 2

- (unsigned int)lastScrollPoint;
- (int)topViewIndex;
- (NSString *)fileBeingRead;
- (int)textSize;
- (BOOL)inverted;

- (void)setLastScrollPoint:(unsigned int)point;
- (void)setTopViewIndex:(int)index;
- (void)setFileBeingRead:(NSString *)file;
- (void)setTextSize:(int)size;
- (void)setInverted:(BOOL)isInverted;

- (BOOL)synchronize;

@end

