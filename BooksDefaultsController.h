/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007
/*

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; version 2
 of the License.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

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

#define TEXTENCODINGKEY @"textEncodingKey"
#define SMARTCONVERSIONKEY @"smartConversionKey"
#define RENDERTABLESKEY @"renderTablesKey"

#define SCROLLSPEEDINDEXKEY @"scrollSpeedIndexKey"

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
- (int)defaultTextEncoding;
- (BOOL)smartConversion;
- (BOOL)renderTables;
- (int)scrollSpeedIndex;
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
- (void)setDefaultTextEncoding:(int)enc;
- (void)setSmartConversion:(BOOL)sc;
- (void)setRenderTables:(BOOL)rt;
- (void)setScrollSpeedIndex:(int)index;

- (BOOL)synchronize;

@end

