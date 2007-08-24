/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "common.h"

@interface BooksDefaultsController : NSObject
{
  unsigned int _lastScrollPoint;
  BOOL _readingText;
  NSString *_fileBeingRead;
  BOOL _inverted;
  NSString *_browserPath;
  NSUserDefaults *sharedDefaults;
}

#define LASTSCROLLPOINTKEY @"lastScrollPointKey"
#define READINGTEXTKEY @"readingTextKey"
#define FILEBEINGREADKEY @"fileBeingReadKey"
#define TEXTSIZEKEY @"textSizeKey"
#define ISINVERTEDKEY @"isInvertedKey"
#define BROWSERFILESKEY @"browserPathsKey"

- (unsigned int)lastScrollPoint;
- (NSString *)fileBeingRead;
- (int)textSize;
- (BOOL)inverted;
- (BOOL)readingText;
- (NSString *)lastBrowserPath;

- (void)setLastScrollPoint:(unsigned int)thePoint;
- (void)setFileBeingRead:(NSString *)file;
- (void)setTextSize:(int)size;
- (void)setInverted:(BOOL)isInverted;
- (void)setReadingText:(BOOL)readingText;
- (void)setLastBrowserPath:(NSString *)browserPath;
- (BOOL)synchronize;

@end

