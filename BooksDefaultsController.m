/// BooksDefaultsController.m, for Books.app by Zachary Brewster-Geisz
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

#import "BooksDefaultsController.h"

@implementation BooksDefaultsController

- (BooksDefaultsController *)init
{
  self = [super init];

  //  sharedDefaults = [[NSUserDefaults standardUserDefaults] retain];

  NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:15];

  [temp setObject:@"-1" forKey:LASTSUBCHAPTERKEY];
  [temp setObject:@"0" forKey:LASTSCROLLPOINTKEY];
  [temp setObject:@"0" forKey:READINGTEXTKEY];
  [temp setObject:@"" forKey:FILEBEINGREADKEY];
  [temp setObject:@"16" forKey:TEXTSIZEKEY];
  [temp setObject:@"0" forKey:ISINVERTEDKEY];
  [temp setObject:@"0" forKey:ENABLESUBCHAPTERINGKEY];
  [temp setObject:EBOOK_PATH forKey:BROWSERFILESKEY];

  [temp setObject:@"TimesNewRoman" forKey:TEXTFONTKEY];
  [temp setObject:@"1" forKey:AUTOHIDE]; //CHANGED: Not used anymore. Autohide setting for each bar
  [temp setObject:@"1" forKey:NAVBAR];
  [temp setObject:@"1" forKey:TOOLBAR];
  [temp setObject:@"0" forKey:FLIPTOOLBAR];
  [temp setObject:@"1" forKey:CHAPTERNAV];
  [temp setObject:@"1" forKey:PAGENAV];
  [temp setObject:[NSMutableDictionary dictionaryWithCapacity:1] forKey:PERSISTENCEKEY];
  [temp setObject:[NSMutableDictionary dictionaryWithCapacity:1] forKey:SUBCHAPTERKEY];
  [temp setObject:[NSNumber numberWithUnsignedInt:0] forKey:TEXTENCODINGKEY];
  //  NSLog(@"temp dictionary: %@\n", temp);
  [temp setObject:@"1" forKey:SMARTCONVERSIONKEY];
  [temp setObject:@"0" forKey:RENDERTABLESKEY];

  [temp setObject:@"1" forKey:SCROLLSPEEDINDEXKEY];
  [[NSUserDefaults standardUserDefaults] registerDefaults:temp];

  [temp release];
  NSMutableDictionary *persistenceSanityCheck =
    [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  if (0 == [persistenceSanityCheck count])
    {
      NSLog(@"sanity check!");
      //This is here for backward compatibility with old persistence system
      NSString *file = [[NSUserDefaults standardUserDefaults] objectForKey:FILEBEINGREADKEY];
      int point = [[NSUserDefaults standardUserDefaults] integerForKey:LASTSCROLLPOINTKEY];
      float adjustedPoint = (float)point / [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
      NSString *pointString = [NSString stringWithFormat:@"%d", (int)adjustedPoint];
      [persistenceSanityCheck setObject:pointString forKey:file];

      [[NSUserDefaults standardUserDefaults] setObject:persistenceSanityCheck forKey:PERSISTENCEKEY];
    }

  NSMutableDictionary *subchapterSanityCheck =
    [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:SUBCHAPTERKEY]];
  if (0 == [subchapterSanityCheck count])
    {
      NSLog(@"subchapter sanity check!");
      NSString *file = [[NSUserDefaults standardUserDefaults] objectForKey:FILEBEINGREADKEY];
      int subchapter = [[NSUserDefaults standardUserDefaults] integerForKey:LASTSUBCHAPTERKEY];
      NSString *subchapterString = [NSString stringWithFormat:@"%d", (int)subchapter];
      [subchapterSanityCheck setObject:subchapterString forKey:file];

      [[NSUserDefaults standardUserDefaults] setObject:subchapterSanityCheck forKey:SUBCHAPTERKEY];
    }

  //  NSLog(@"Persistence dictionary:\n%@", [[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]);
  return self;
}

- (unsigned int)lastSubchapter
{
  int subchapter = [[NSUserDefaults standardUserDefaults] integerForKey:LASTSUBCHAPTERKEY];

  // sanity check for older prefs without subchaptering support...
  if (subchapter == -1) // wasn't previously set
     subchapter = 0;

  return (unsigned int) subchapter;
}

- (unsigned int)lastScrollPoint
{
  BOOL subchapteringEnabled = [self subchapteringEnabled];
  int subchapter = [self lastSubchapter];
  int scrollPoint = [[NSUserDefaults standardUserDefaults] integerForKey:LASTSCROLLPOINTKEY];

  // sanity check for older prefs without subchaptering support...
  if (subchapteringEnabled && (subchapter == -1)) // wasn't previously set
     scrollPoint = 0;

  return (unsigned int) scrollPoint;
}

- (BOOL)subchapterExistsForFile:(NSString *)filename
{
  NSDictionary *blah = [[NSUserDefaults standardUserDefaults] objectForKey:SUBCHAPTERKEY];
  return (nil != [blah objectForKey:filename]);
}

- (BOOL)scrollPointExistsForFile:(NSString *)filename
{
  NSDictionary *blah = [[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY];
  return (nil != [blah objectForKey:filename]);
}

- (unsigned int)lastSubchapterForFile:(NSString *)filename
  // Returns subchapter
{
  NSDictionary *blah = [[NSUserDefaults standardUserDefaults] objectForKey:SUBCHAPTERKEY];
  NSString *subchapterString = [blah objectForKey:filename];

  if (nil == subchapterString)
    return 0;
  else
    return [subchapterString intValue];
}

- (unsigned int)lastScrollPointForFile:(NSString *)filename
  // Returns scroll point adjusted by the font size.
{
  NSDictionary *blah = [[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY];
  NSString *scrollpointString = [blah objectForKey:filename];
  BOOL subchapteringEnabled = [self subchapteringEnabled];
  BOOL subchapterExistsForFile = [self subchapterExistsForFile:filename];

  if (nil == scrollpointString)
    return 0;
  else if (subchapteringEnabled && !subchapterExistsForFile)
  	return 0;
  else
    {
      int fontsize = [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
      // NSLog(@"scroll point: %d", (unsigned int)[scrollpointString intValue]);
      return (unsigned int)([scrollpointString intValue] * fontsize);
    }
}

- (NSString *)fileBeingRead
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:FILEBEINGREADKEY];
}

- (int)textSize
{
  return [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
}

- (BOOL)inverted
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:ISINVERTEDKEY];
}

- (BOOL)subchapteringEnabled
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:ENABLESUBCHAPTERINGKEY];
}

- (BOOL)readingText
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:READINGTEXTKEY];
}

- (NSString *)lastBrowserPath
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:BROWSERFILESKEY];
}

- (unsigned int)defaultTextEncoding
{
  id num = [[NSUserDefaults standardUserDefaults] objectForKey:TEXTENCODINGKEY];
  if ([num respondsToSelector:@selector(unsignedIntValue:)])  
    return [num unsignedIntValue];
  else
    return (unsigned int)[num intValue];
}

- (BOOL)smartConversion
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:SMARTCONVERSIONKEY];
}

- (BOOL)renderTables
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:RENDERTABLESKEY];
}

- (int)scrollSpeedIndex
{
  return [[NSUserDefaults standardUserDefaults] integerForKey:SCROLLSPEEDINDEXKEY];
}

- (void)setLastSubchapter:(unsigned int)thePoint
{
  [[NSUserDefaults standardUserDefaults] setInteger:thePoint forKey:LASTSUBCHAPTERKEY];
}

- (void)setLastScrollPoint:(unsigned int)thePoint
{
  [[NSUserDefaults standardUserDefaults] setInteger:thePoint forKey:LASTSCROLLPOINTKEY];
}

- (void)setLastSubchapter:(unsigned int)subchapter forFile:(NSString *)file
  // Adjusts the scroll point based on the font size.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:SUBCHAPTERKEY]];
  NSString *subchapterString = [NSString stringWithFormat:@"%d", subchapter];
  [tempDict setObject:subchapterString forKey:file];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:SUBCHAPTERKEY];
}

- (void)setLastScrollPoint:(unsigned int)thePoint forFile:(NSString *)file
  // Adjusts the scroll point based on the font size.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  thePoint /= [[NSUserDefaults standardUserDefaults] integerForKey:TEXTSIZEKEY];
  NSString *thePointString = [NSString stringWithFormat:@"%d", thePoint];
  [tempDict setObject:thePointString forKey:file];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
}

- (void)removeSubchapterForFile:(NSString *)file
  // Call this method when deleting a single text/HTML file from
  // the FileBrowser.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:SUBCHAPTERKEY]];
  [tempDict removeObjectForKey:file];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:SUBCHAPTERKEY];
}

- (void)removeScrollPointForFile:(NSString *)file
  // Call this method when deleting a single text/HTML file from
  // the FileBrowser.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  [tempDict removeObjectForKey:file];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
}

- (void)removeSubchaptersForDirectory:(NSString *)dir
  // This method should be called when deleting a folder from the
  // FileBrowser, so the prefs file doesn't get crusty with deleted
  // books.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:SUBCHAPTERKEY]];
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
					enumeratorAtPath:dir];
 if (nil != enumerator)
   {
     NSString *subpath;
     while (nil != (subpath = [enumerator nextObject]))
       {
	 [tempDict removeObjectForKey:[dir stringByAppendingPathComponent:subpath]];
       }
   }
 [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:SUBCHAPTERKEY];
 //phew!
}

- (void)removeScrollPointsForDirectory:(NSString *)dir
  // This method should be called when deleting a folder from the
  // FileBrowser, so the prefs file doesn't get crusty with deleted
  // books.
{
  NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:PERSISTENCEKEY]];
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
					enumeratorAtPath:dir];
 if (nil != enumerator)
   {
     NSString *subpath;
     while (nil != (subpath = [enumerator nextObject]))
       {
	 [tempDict removeObjectForKey:[dir stringByAppendingPathComponent:subpath]];
       }
   }
 [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
 //phew!
}

- (void)removeAllSubchapters
{
  NSDictionary *tempDict = [NSDictionary dictionaryWithObject:@"0" forKey:@""];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:SUBCHAPTERKEY];
  [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:LASTSUBCHAPTERKEY];
}

- (void)removeAllScrollPoints
{
  NSDictionary *tempDict = [NSDictionary dictionaryWithObject:@"0" forKey:@""];
  [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:PERSISTENCEKEY];
  [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:LASTSCROLLPOINTKEY];
}

- (void)setLastBrowserPath:(NSString *)browserPath
{
  [[NSUserDefaults standardUserDefaults] setObject:browserPath forKey:BROWSERFILESKEY];
}

- (void)setFileBeingRead:(NSString *)file
{
  [[NSUserDefaults standardUserDefaults] setObject:file forKey:FILEBEINGREADKEY];
}

- (void)setTextSize:(int)size
{
  [[NSUserDefaults standardUserDefaults] setInteger:size forKey:TEXTSIZEKEY];
}

- (void)setInverted:(BOOL)isInverted
{
  [[NSUserDefaults standardUserDefaults] setBool:isInverted forKey:ISINVERTEDKEY];
}

- (void)setSubchapteringEnabled:(BOOL)isEnabled
{
  [[NSUserDefaults standardUserDefaults] setBool:isEnabled forKey:ENABLESUBCHAPTERINGKEY];
}

- (void)setReadingText:(BOOL)readingText
{
  [[NSUserDefaults standardUserDefaults] setBool:readingText forKey:READINGTEXTKEY];
}

- (void)setTextFont:(NSString *)font
{
  [[NSUserDefaults standardUserDefaults] setObject:font forKey:TEXTFONTKEY];
}

- (NSString *)textFont
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:TEXTFONTKEY];
}

- (BOOL)autohide
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:AUTOHIDE];
}

- (BOOL)navbar
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:NAVBAR];
}

- (BOOL)toolbar
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:TOOLBAR];
}

- (BOOL)flipped
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:FLIPTOOLBAR];
}

- (BOOL)chapternav
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:CHAPTERNAV];
}

- (BOOL)pagenav
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:PAGENAV];
}

- (void)setAutohide:(BOOL)isAutohide
{
  [[NSUserDefaults standardUserDefaults] setBool:isAutohide forKey:AUTOHIDE];
}

- (void)setNavbar:(BOOL)isNavbar
{
  [[NSUserDefaults standardUserDefaults] setBool:isNavbar forKey:NAVBAR];
}

- (void)setToolbar:(BOOL)isToolbar
{
  [[NSUserDefaults standardUserDefaults] setBool:isToolbar forKey:TOOLBAR];
}

- (void)setFlipped:(BOOL)isFlipped
{
  [[NSUserDefaults standardUserDefaults] setBool:isFlipped forKey:FLIPTOOLBAR];
  _toolbarShouldUpdate = YES;
}

- (void)setChapternav:(BOOL)isChpaternav
{
  [[NSUserDefaults standardUserDefaults] setBool:isChpaternav forKey:CHAPTERNAV];
  _toolbarShouldUpdate = YES;
}

- (void)setPagenav:(BOOL)isPagenav
{
  [[NSUserDefaults standardUserDefaults] setBool:isPagenav forKey:PAGENAV];
  _toolbarShouldUpdate = YES;
}

- (void)setDefaultTextEncoding:(unsigned int)enc
{
  NSNumber *num = [NSNumber numberWithUnsignedInt:enc];
  [[NSUserDefaults standardUserDefaults] setObject:num forKey:TEXTENCODINGKEY];
}

- (void)setSmartConversion:(BOOL)sc
{
  [[NSUserDefaults standardUserDefaults] setBool:sc forKey:SMARTCONVERSIONKEY];
}

- (void)setRenderTables:(BOOL)rt
{
  [[NSUserDefaults standardUserDefaults] setBool:rt forKey:RENDERTABLESKEY];
}

- (void)setScrollSpeedIndex:(int)index
{
  [[NSUserDefaults standardUserDefaults] setInteger:index forKey:SCROLLSPEEDINDEXKEY];
  [[NSNotificationCenter defaultCenter] postNotificationName:CHANGEDSCROLLSPEED object:self];
}

- (BOOL)synchronize
{
  if (_toolbarShouldUpdate) [[NSNotificationCenter defaultCenter] postNotificationName:@"toolbarDefaultsChanged" object:self];
  return [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
  BOOL unused = [[NSUserDefaults standardUserDefaults] synchronize];
  //  [fileBeingRead release];
  //  [sharedDefaults release];
  [super dealloc];
}


@end
