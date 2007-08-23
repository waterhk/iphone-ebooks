/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface BooksDefaultsController : NSObject
{
  NSUserDefaults *sharedDefaults;
}

#define LASTSCROLLPOINTKEY @"lastScrollPointKey"
#define READINGTEXTKEY @"readingTextKey"
#define FILEBEINGREADKEY @"fileBeingReadKey"
#define TEXTSIZEKEY @"textSizeKey"
#define ISINVERTEDKEY @"isInvertedKey"
#define BROWSERFILESKEY @"browserFilesKey"

- (unsigned int)lastScrollPoint;
- (NSString *)fileBeingRead;
- (int)textSize;
- (BOOL)inverted;
- (BOOL)readingText;
- (NSArray *)browserArray;

- (void)setLastScrollPoint:(unsigned int)point;
- (void)setFileBeingRead:(NSString *)file;
- (void)setTextSize:(int)size;
- (void)setInverted:(BOOL)isInverted;
- (void)setReadingText:(BOOL)readingText;
- (void)setBrowserArray:(NSArray *)browserArray;
- (BOOL)synchronize;

@end

