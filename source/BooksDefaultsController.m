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
#import "UIOrientingApplication.h"
#import <UIKit/UIHardware.h>

#define DEBUG 0
#if DEBUG
# define Debug(x...) GSLog(x)
#else
# define Debug(x...)
#endif

@implementation BooksDefaultsController

+ (NSString*) defaultEBookPath
{
	static NSString *_default_EBookPath;
	_default_EBookPath	= [[NSHomeDirectory() stringByAppendingPathComponent: EBOOK_PATH_SUFFIX] retain];
	return _default_EBookPath;
}

- (id) init
{
	if(self = [super init]) {
    NSMutableDictionary *temp;
    
    _toolbarShouldUpdate = NO;
    
    _defaults = [[NSUserDefaults standardUserDefaults] retain];

    temp = [[NSMutableDictionary alloc] initWithCapacity:18];
    [temp setObject:@"16" forKey:TEXTSIZEKEY];
    [temp setObject:@"0" forKey:ISINVERTEDKEY];
    [temp setObject:[BooksDefaultsController defaultEBookPath] forKey:BROWSERFILESKEY];
    [temp setObject:@"TimesNewRoman" forKey:TEXTFONTKEY];
    [temp setObject:@"1" forKey:NAVBAR];
    [temp setObject:@"1" forKey:TOOLBAR];
    [temp setObject:@"0" forKey:FLIPTOOLBAR];
    [temp setObject:@"1" forKey:CHAPTERNAV];
    [temp setObject:@"1" forKey:PAGENAV];
    [temp setObject:[NSNumber numberWithUnsignedInt:0] forKey:TEXTENCODINGKEY];
    [temp setObject:@"1" forKey:SMARTCONVERSIONKEY];
    [temp setObject:@"0" forKey:RENDERTABLESKEY];
    [temp setObject:@"0" forKey:ENABLESUBCHAPTERINGKEY];
    [temp setObject:@"1" forKey:SCROLLSPEEDINDEXKEY];
    [temp setObject:[NSMutableDictionary dictionaryWithCapacity:1] forKey:FILESPECIFICDATAKEY];
    [temp setObject:@"0" forKey:ISROTATELOCKEDKEY];
    [temp setObject:@"0" forKey:INVERSENAVZONEKEY];
    [temp setObject:@"0" forKey:ENABLESUBCHAPTERINGKEY];
    [temp setObject:@"1" forKey:ISROTATELOCKEDKEY];
    

    [_defaults registerDefaults:temp];
    [temp release];

    [self updateOldPreferences];
  }
  
	return self;
}

- (void) updateOldPreferences
{
	NSDictionary *persistenceData;
	NSDictionary *subchapterData;
	NSDictionary *fixedPerFileData;

	persistenceData  = [_defaults objectForKey:PERSISTENCEKEY];
	subchapterData   = [_defaults objectForKey:SUBCHAPTERKEY];
	fixedPerFileData = [_defaults objectForKey:FILESPECIFICDATAKEY];

	if (persistenceData == nil) 
	{
		if ([_defaults objectForKey:LASTSCROLLPOINTKEY] != nil)
		{
			NSString *filename      = [self lastBrowserPath];
			float     point         = (float) [_defaults integerForKey:LASTSCROLLPOINTKEY];
			float     textSize      = (float) [self textSize];
			int       adjPoint      = (int) (point / textSize);
			BOOL      subchaptering = [self subchapteringEnabled];

			[self setLastSubchapter:0 forFile:filename];
			[self setLastScrollPoint:adjPoint forSubchapter:0 forFile:filename];
			[self setSubchapteringEnabled:subchaptering forFile:filename];
		}
	}
	else
	{
		NSEnumerator *enumerator = [persistenceData keyEnumerator];
		NSString     *filename;

		while (filename = [enumerator nextObject])
		{
			int point = [[persistenceData objectForKey:filename] intValue];
			int subchapter;

			if ([filename length] == 0)
				continue;

			if (subchapterData != nil)
				subchapter = [[subchapterData objectForKey:filename] intValue];
			else
				subchapter = 0;

			[self setLastSubchapter:subchapter forFile:filename];
			[self setLastScrollPoint:point
					   forSubchapter:subchapter
							 forFile:filename];
		}
	}

	[_defaults removeObjectForKey:PERSISTENCEKEY];
	[_defaults removeObjectForKey:SUBCHAPTERKEY];
	[_defaults removeObjectForKey:LASTSCROLLPOINTKEY];
	[_defaults removeObjectForKey:LASTSUBCHAPTERKEY];
	[_defaults removeObjectForKey:AUTOHIDE];
	return;
}

- (int)textSize
{
	int textSize = [_defaults integerForKey:TEXTSIZEKEY];

	Debug (@"[_defaults textSize] = %d\n", textSize);
	return textSize;
}

- (void)setTextSize:(int)size
{
	[_defaults setInteger:size forKey:TEXTSIZEKEY];
}

- (BOOL)inverted
{
	BOOL inverted = [_defaults boolForKey:ISINVERTEDKEY];

	Debug (@"[_defaults inverted] = %s", (inverted) ? "YES" : "NO");
	return inverted;
}

- (void)setInverted:(BOOL)isInverted
{
	[_defaults setBool:isInverted forKey:ISINVERTEDKEY];
}

- (BOOL)subchapteringEnabled
{
	BOOL enabled = [_defaults boolForKey:ENABLESUBCHAPTERINGKEY];

	Debug (@"[_defaults subchapteringEnabled] = %s", (enabled) ? "YES" : "NO");
	return enabled;
}

- (void)setSubchapteringEnabled:(BOOL)isEnabled
{
	[_defaults setBool:isEnabled forKey:ENABLESUBCHAPTERINGKEY];
}

- (NSString *)lastBrowserPath
{
	NSString *path = [[_defaults objectForKey:BROWSERFILESKEY] stringByExpandingTildeInPath];
	NSString * lDefaultPath = [BooksDefaultsController defaultEBookPath];
	if (![path hasPrefix:lDefaultPath])
	{

		NSString *bodyText = [NSString stringWithFormat:@"The last visited directory was %@ this is not a subdirectory of the Books directory (%@) this is typically the sign of a 1.1.2 to 1.1.3 migration.\n  Current path reset to the default one.  If you haven't recently migrated you may have a corrupt preference file.", path, lDefaultPath];
		path = lDefaultPath;
		CGRect rect = [UIHardware fullScreenApplicationContentRect];
		UIAlertSheet * alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - TOOLBAR_HEIGHT, rect.size.width,240)];
		[alertSheet setTitle:@"Path reset"];
		[alertSheet setBodyText:bodyText];
		[alertSheet addButtonWithTitle:@"OK"];
		[alertSheet setDelegate: self];
		[alertSheet popupAlertAnimated:YES];
		[alertSheet autorelease];
		[_defaults setObject:path forKey:BROWSERFILESKEY];
	}
	Debug (@"[_defaults lastBrowserPath] = %@", path);
	return path;
}

// Delegate methods
- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button {
	[sheet dismissAnimated:YES];
}

- (void)setLastBrowserPath:(NSString *)browserPath
{
	[_defaults setObject:browserPath forKey:BROWSERFILESKEY];
}

- (unsigned int)defaultTextEncoding
{
	id           num = [_defaults objectForKey:TEXTENCODINGKEY];
	unsigned int value;

	if ([num respondsToSelector:@selector(unsignedIntValue:)])  
		value = [num unsignedIntValue];
	else
		value = (unsigned int)[num intValue];

	Debug (@"[_defaults defaultTextEncoding] = %d", value);
	return value;
}

- (void)setDefaultTextEncoding:(unsigned int)enc
{
	NSNumber *num = [NSNumber numberWithUnsignedInt:enc];
	[_defaults setObject:num forKey:TEXTENCODINGKEY];
}

- (BOOL)smartConversion
{
	BOOL value = [_defaults boolForKey:SMARTCONVERSIONKEY];

	Debug (@"[_defaults smartConversion] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setSmartConversion:(BOOL)sc
{
	[_defaults setBool:sc forKey:SMARTCONVERSIONKEY];
}

- (BOOL)renderTables
{
	BOOL value = [_defaults boolForKey:RENDERTABLESKEY];

	Debug (@"[_defaults renderTables] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setRenderTables:(BOOL)rt
{
	[_defaults setBool:rt forKey:RENDERTABLESKEY];
}

- (int)scrollSpeedIndex
{
	int value = [_defaults integerForKey:SCROLLSPEEDINDEXKEY];

	Debug (@"[_defaults scrollSpeedIndex] = %d", value);
	return value;
}

- (void)setScrollSpeedIndex:(int)index
{
	[_defaults setInteger:index forKey:SCROLLSPEEDINDEXKEY];
	[[NSNotificationCenter defaultCenter] postNotificationName:CHANGEDSCROLLSPEED object:self];
}

- (NSString *)textFont
{
	NSString *font = [_defaults objectForKey:TEXTFONTKEY];

	Debug (@"[_defaults textFont] = %s", [font cString]);
	return font;
}

- (void)setTextFont:(NSString *)font
{
	[_defaults setObject:font forKey:TEXTFONTKEY];
}

- (BOOL)navbar
{
	BOOL value = [_defaults boolForKey:NAVBAR];

	Debug (@"[_defaults navbar] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setNavbar:(BOOL)isNavbar
{
	[_defaults setBool:isNavbar forKey:NAVBAR];
}


- (BOOL)toolbar
{
	BOOL value = [_defaults boolForKey:TOOLBAR];

	Debug (@"[_defaults toolbar] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setToolbar:(BOOL)isToolbar
{
	[_defaults setBool:isToolbar forKey:TOOLBAR];
}

- (BOOL)flipped
{
	BOOL value = [_defaults boolForKey:FLIPTOOLBAR];

	Debug (@"[_defaults flipped] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setFlipped:(BOOL)isFlipped
{
	GSLog(@"setFlipped");
	[_defaults setBool:isFlipped forKey:FLIPTOOLBAR];
	_toolbarShouldUpdate = YES;
}

/**
 * Query rotation status.
 */
- (BOOL)isRotateLocked {
	return [_defaults boolForKey:ISROTATELOCKEDKEY];
}

/**
 * Save rotation status.
 */
- (void)setRotateLocked:(BOOL)isRotateLocked {
	[_defaults setBool:isRotateLocked forKey:ISROTATELOCKEDKEY];
  UIOrientingApplication *app = (UIOrientingApplication*)UIApp;
  if(isRotateLocked) {
    [app lockUIOrientation];
  } else {
    [app unlockUIOrientation];
  }
}

- (BOOL)inverseNavZone
{
	BOOL value = [_defaults boolForKey:INVERSENAVZONEKEY];
	return value;
}

- (void)setInverseNavZone:(BOOL)inverted
{
	[_defaults setBool:inverted forKey:INVERSENAVZONEKEY];
}- 

(BOOL)enlargeNavZone
{
	BOOL value = [_defaults boolForKey:ENLARGENAVZONEKEY];
	return value;
}

- (void)setEnlargeNavZone:(BOOL)enlarged
{
	[_defaults setBool:enlarged forKey:ENLARGENAVZONEKEY];
}




- (BOOL)chapternav
{
	BOOL value = [_defaults boolForKey:CHAPTERNAV];

	Debug (@"[_defaults chapternav] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setChapternav:(BOOL)isChpaternav
{
	GSLog(@"setChapternav");
	[_defaults setBool:isChpaternav forKey:CHAPTERNAV];
	_toolbarShouldUpdate = YES;
}

- (BOOL)pagenav
{
	BOOL value = [_defaults boolForKey:PAGENAV];

	Debug (@"[_defaults pagenav] = %s", (value) ? "YES" : "NO");
	return value;
}

- (void)setPagenav:(BOOL)isPagenav
{
	GSLog(@"setPageNav");
	[_defaults setBool:isPagenav forKey:PAGENAV];
	_toolbarShouldUpdate = YES;
}

- (BOOL)synchronize
{
	GSLog(@"default:synchronize");
	if (_toolbarShouldUpdate) {
    [[NSNotificationCenter defaultCenter] postNotificationName:TOOLBAR_DEFAULTS_CHANGED_NOTIFICATION object:self];
  }
	_toolbarShouldUpdate = NO;

	return [_defaults synchronize];
}

- (void)dealloc
{
	(void) [_defaults synchronize];
	[_defaults release];

	[super dealloc];
}

/*
 * Grouping of per-book preferences access routines
 */
- (BOOL) dataExistsForFile: (NSString *) filename
{
	NSDictionary *perFileData = [_defaults objectForKey:FILESPECIFICDATAKEY];

	if ([perFileData objectForKey:filename] == nil)
		return FALSE;

	return TRUE;
}

- (BOOL) subchapteringEnabledForFile: (NSString *) filename
{
	NSDictionary *perFileData = [_defaults objectForKey:FILESPECIFICDATAKEY];
	NSDictionary *bookData    = [perFileData objectForKey:filename];
	BOOL          enabled     = ([[bookData objectForKey:FILESUBCHAPTERENABLE]
									   intValue]) ? YES : NO;

	if (bookData == nil)
		enabled =  NO;

	return enabled;
}

- (void) setSubchapteringEnabled: (BOOL) enabled
						 forFile: (NSString *) filename
{
	NSMutableDictionary *perFileData = [NSMutableDictionary dictionaryWithDictionary:[_defaults objectForKey:FILESPECIFICDATAKEY]];
	NSMutableDictionary *bookData = [NSMutableDictionary dictionaryWithDictionary:[perFileData objectForKey:filename]];
	NSString            *enableStr = [NSString stringWithFormat:@"%d", (enabled) ? 1 : 0];

	[bookData setObject:enableStr forKey:FILESUBCHAPTERENABLE];
	[perFileData setObject:bookData forKey:filename];
	[_defaults setObject:perFileData forKey:FILESPECIFICDATAKEY];
}

- (unsigned int) lastSubchapterForFile: (NSString *) filename
{
	NSDictionary *perFileData = [_defaults objectForKey:FILESPECIFICDATAKEY];
	NSDictionary *bookData    = [perFileData objectForKey:filename];
	int           subchapter  = [[bookData objectForKey:FILECURRENTSUBCHAPTER]
		intValue];

	if (bookData == nil)
		subchapter = 0;

	return subchapter;
}

- (void) setLastSubchapter: (unsigned int) subchapter
				   forFile: (NSString *) filename
{
	NSMutableDictionary *perFileData = [NSMutableDictionary dictionaryWithDictionary:[_defaults objectForKey:FILESPECIFICDATAKEY]];
	NSMutableDictionary *bookData = [NSMutableDictionary dictionaryWithDictionary:[perFileData objectForKey:filename]];
	NSString            *subchapStr = [NSString stringWithFormat:@"%d", subchapter];

	[bookData setObject:subchapStr forKey:FILECURRENTSUBCHAPTER];
	[perFileData setObject:bookData forKey:filename];
	[_defaults setObject:perFileData forKey:FILESPECIFICDATAKEY];
}

/**
 * Get the scroll point last visible for the given file and chapter.
 */
- (float)lastScrollPointForFile: (NSString *) filename inSubchapter: (unsigned int) subchapter {
	NSString     *location     = [NSString stringWithFormat:@"%d", subchapter];
	NSDictionary *perFileData  = [_defaults objectForKey:FILESPECIFICDATAKEY];
	NSDictionary *bookData     = [perFileData objectForKey:filename];
	NSDictionary *locationData = [bookData objectForKey:FILELOCPERSUBCHAPTER];
	float           scrollPoint  = [[locationData objectForKey:location] floatValue];

	if ((bookData == nil) || (locationData == nil))
		scrollPoint = 0;

	return scrollPoint;
}

/**
 * Save the last visible point for this file.
 */
- (void) setLastScrollPoint:(float)scrollPoint forSubchapter:(unsigned int)subchapter forFile:(NSString *)filename {
	NSString            *location     = [NSString stringWithFormat:@"%d", subchapter];
	NSMutableDictionary *perFileData  = [NSMutableDictionary dictionaryWithDictionary:[_defaults objectForKey:FILESPECIFICDATAKEY]];
	NSMutableDictionary *bookData     = [NSMutableDictionary dictionaryWithDictionary:[perFileData objectForKey:filename]];
	NSMutableDictionary *locationData = [NSMutableDictionary dictionaryWithDictionary:[bookData objectForKey:FILELOCPERSUBCHAPTER]];
	NSNumber            *scrollStr    = [NSNumber numberWithFloat:scrollPoint];

	[locationData setObject:scrollStr forKey:location];
	[bookData setObject:locationData forKey:FILELOCPERSUBCHAPTER];
	[perFileData setObject:bookData forKey:filename];
	[_defaults setObject:perFileData forKey:FILESPECIFICDATAKEY];
}

- (void) removePerFileDataForFile: (NSString *) filename
{
	NSMutableDictionary *perFileData  = [NSMutableDictionary dictionaryWithDictionary:[_defaults objectForKey:FILESPECIFICDATAKEY]];

	[perFileData removeObjectForKey:filename];
	[_defaults setObject:perFileData forKey:FILESPECIFICDATAKEY];
}

- (void) removePerFileDataForDirectory: (NSString *) directory
{
	NSMutableDictionary *perFileData    = [NSMutableDictionary dictionaryWithDictionary:[_defaults objectForKey:FILESPECIFICDATAKEY]];
	NSArray             *keys           = [perFileData allKeys];
	NSEnumerator        *enumerator     = [keys objectEnumerator];
	NSRange              directoryRange = { 0, [directory length] };
	NSString            *filename;
	GSLog(@"BooksDefaultsController removePerFileDataForDirectory:%@", directory);
	while (filename = [enumerator nextObject])
	{
		GSLog(@"current filename: %@", filename);
		if ([filename compare:directory
					  options:NSLiteralSearch
						range:directoryRange] == NSOrderedSame)
		{
			[perFileData removeObjectForKey:filename];
			GSLog(@"removing key");
		}
	}

	[_defaults setObject:perFileData forKey:FILESPECIFICDATAKEY];
	return;
}

- (void) removePerFileData
{
	NSMutableDictionary *perFileData    = [NSMutableDictionary dictionaryWithDictionary:[_defaults objectForKey:FILESPECIFICDATAKEY]];
	NSArray             *keys           = [perFileData allKeys];
	NSEnumerator        *enumerator     = [keys objectEnumerator];
	NSString            *filename;

	while (filename = [enumerator nextObject])
		[perFileData removeObjectForKey:filename];

	[_defaults setObject:perFileData forKey:FILESPECIFICDATAKEY];
	return;
}

//Bcc makes it into a singleton
static BooksDefaultsController *sharedBooksDefaultsController = nil;

+ (BooksDefaultsController*)sharedBooksDefaultsController {
	@synchronized(self) {
		if (sharedBooksDefaultsController == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
  
	return sharedBooksDefaultsController;
}



+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedBooksDefaultsController == nil) {
			sharedBooksDefaultsController = [super allocWithZone:zone];
			return sharedBooksDefaultsController;  // assignment and return on first allocation
		}
	}

	return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}



- (id)retain {
	return self;
}



- (unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}



- (void)release {
	//do nothing
}



- (id)autorelease {
	return self;
}
@end
