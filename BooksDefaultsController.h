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
  BOOL _toolbarShouldUpdate;
}

#define LASTSCROLLPOINTKEY @"lastScrollPointKey"
#define READINGTEXTKEY @"readingTextKey"
#define FILEBEINGREADKEY @"fileBeingReadKey"
#define TEXTSIZEKEY @"textSizeKey"
#define ISINVERTEDKEY @"isInvertedKey"
#define BROWSERFILESKEY @"browserPathsKey"

#define PERSISTENCEKEY @"persistenceDictionaryKey"

#define TEXTFONTKEY @"textFontKey"
#define	AUTOHIDE @"autohideKey"
#define NAVBAR @"navbarKey"
#define TOOLBAR @"toolbarKey"
#define FLIPTOOLBAR @"flipToolbarKey"
#define CHAPTERNAV @"chapterNavKey"
#define PAGENAV @"pageNavKey"

- (unsigned int)lastScrollPoint;
- (unsigned int)lastScrollPointForFile:(NSString *)file;
- (NSString *)fileBeingRead;
- (int)textSize;
- (BOOL)inverted;
- (BOOL)readingText;
- (NSString *)lastBrowserPath;
- (BOOL)autohide;
- (BOOL)navbar;
- (BOOL)toolbar;
- (BOOL)flipped;
- (NSString *)textFont;
- (BOOL)chapternav;
- (BOOL)pagenav;

- (void)setLastScrollPoint:(unsigned int)thePoint;
- (void)setLastScrollPoint:(unsigned int)thePoint forFile:(NSString *)file;
- (void)removeScrollPointForFile:(NSString *)theFile;
- (void)removeScrollPointsForDirectory:(NSString *)dir;
- (void)removeAllScrollPoints;
- (void)setFileBeingRead:(NSString *)file;
- (void)setTextSize:(int)size;
- (void)setInverted:(BOOL)isInverted;
- (void)setReadingText:(BOOL)readingText;
- (void)setLastBrowserPath:(NSString *)browserPath;
- (void)setTextFont:(NSString *)font;
- (void)setAutohide:(BOOL)isAutohide;
- (void)setNavbar:(BOOL)isNavbar;
- (void)setToolbar:(BOOL)isToolbar;
- (void)setFlipped:(BOOL)isFlipped;
- (void)setChapternav:(BOOL)isChpaternav;
- (void)setPagenav:(BOOL)isPagenav;

- (BOOL)synchronize;

@end

