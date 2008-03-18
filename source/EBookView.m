/* EBookView, by Zachary Brewster-Geisz for Books.app

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
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>

#import "EBookView.h"
#import "BooksDefaultsController.h"
#import "palm/palmconvert.h"
#import "ChapteredHTML.h"

#define ENCODING_LIST {[defaults defaultTextEncoding], NSUTF8StringEncoding, NSISOLatin1StringEncoding, \
	NSWindowsCP1252StringEncoding, NSMacOSRomanStringEncoding,NSASCIIStringEncoding, -1}; 



@implementation EBookView

- (id)initWithFrame:(struct CGRect)rect {
	CGRect lFrame = rect;
	if (rect.size.width < rect.size.height) {
		lFrame.size.width = rect.size.height;
	}
  
	[super initWithFrame:lFrame];
	[super setFrame:rect];	
	//  tapinfo = [[UIViewTapInfo alloc] initWithDelegate:self view:self];

	size = 16.0f;

	chapteredHTML = [[ChapteredHTML alloc] init];
	subchapter    = 0;
	defaults      = [BooksDefaultsController sharedBooksDefaultsController]; 
  
	[self setAdjustForContentSizeChange:YES];
	[self setEditable:NO];

	[self setTextSize:size];
	[self setTextFont:@"TimesNewRoman"];

	[self setAllowsRubberBanding:YES];
	[self setBottomBufferHeight:0.0f];

	[self scrollToMakeCaretVisible:NO];

	[self setScrollDecelerationFactor:0.996f];
	
	[self setTapDelegate:self];
	[self setScrollerIndicatorsPinToContent:NO];
	
  lastVisibleRect = [self visibleRect];
	[self scrollSpeedDidChange:nil];
  
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(scrollSpeedDidChange:)
												 name:CHANGEDSCROLLSPEED
											   object:nil];

	return self;
}

- (void)heartbeatCallback:(id)unused {
	if ((![self isScrolling]) && (![self isDecelerating])) {
		lastVisibleRect = [self visibleRect];
	}

	if (_heartbeatDelegate != nil) {
		if ([_heartbeatDelegate respondsToSelector:@selector(heartbeatCallback:)]) {
			 [_heartbeatDelegate heartbeatCallback:self];
		} else {
			[NSException raise:NSInternalInconsistencyException
						format:@"Delegate doesn't respond to selector"];
		}
	}
}

- (void)setHeartbeatDelegate:(id)delegate {
	_heartbeatDelegate = delegate;
	[self startHeartbeat:@selector(heartbeatCallback:) inRunLoopMode:nil];
}

- (void)hideNavbars {
	if (_heartbeatDelegate != nil) {
		if ([_heartbeatDelegate respondsToSelector:@selector(hideNavbars)]) {
			[_heartbeatDelegate hideNavbars];
		} else {
			[NSException raise:NSInternalInconsistencyException
						format:@"Delegate doesn't respond to selector"];
		}
	}
}

/*
   - (void)drawRect:(struct CGRect)rect
   {

   if (nil != path)
   {
   NSString *coverPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover.jpg"];
   UIImage *img = [UIImage imageAtPath:coverPath];
   if (nil != img)
   {
   [img compositeToPoint:CGPointMake(0,0) operation:1];
   }
   }

   [super drawRect:rect];
   }
   */

- (void)toggleNavbars {
	if (_heartbeatDelegate != nil) {
		if ([_heartbeatDelegate respondsToSelector:@selector(toggleNavbars)]) {
			[_heartbeatDelegate toggleNavbars];
		} else {
			[NSException raise:NSInternalInconsistencyException
						format:@"Delegate doesn't respond to selector"];
		}
	}
}

/**
 * Return the current path.
 */
- (NSString *)currentPath {
	return path;
}
-(void)reflowBook
{
			[self recalculateStyle];
			[self webViewDidChange:self];
			[self setNeedsDisplay];
}
/**
 * Increase on-screen text size.
 *
 * "A noble spirit embiggens the smallest man." -- Jebediah Springfield
 */
	- (void)embiggenText {
		if (size < 36.0f)
		{
			struct CGRect oldRect = [self visibleRect];
			struct CGRect totalRect = [[self _webView] frame];
			//		GSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
			float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
			float scrollFactor = middleRect / totalRect.size.height;
			size += 2.0f;
			[self setTextSize:size];
			[self reflowBook];


			totalRect = [[self _webView] frame];
			middleRect = scrollFactor * totalRect.size.height;
			oldRect.origin.y = middleRect - (oldRect.size.height / 2);
			//		GSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
			[self scrollPointVisibleAtTopLeft:oldRect.origin animated:NO];
		}
	}

/**
 * Shrink on-screen text size.
 *
 * "What the f--- does ensmallen mean?" -- Zach Brewster-Geisz
 */
	- (void)ensmallenText {
		if (size > 10.0f)
		{
			struct CGRect oldRect = [self visibleRect];
			struct CGRect totalRect = [[self _webView] frame];
			//		GSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
			float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
			float scrollFactor = middleRect / totalRect.size.height;
			size -= 2.0f;
			[self setTextSize:size];
			
			[self reflowBook];

			totalRect = [[self _webView] frame];
			middleRect = scrollFactor * totalRect.size.height;
			oldRect.origin.y = middleRect - (oldRect.size.height / 2);
			//		GSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
			[self scrollPointVisibleAtTopLeft:oldRect.origin animated:NO];
		}
	}


// None of these tap methods work yet.  They may never work.
- (void)handleDoubleTapEvent:(struct __GSEvent *)event {
	[self embiggenText];
	//[super handleDoubleTapEvent:event];
}

- (void)handleSingleTapEvent:(struct __GSEvent *)event {
	[self ensmallenText];
	//[super handleDoubleTapEvent:event];
}
/*
   - (BOOL)bodyAlwaysFillsFrame
   {//experiment!
   return NO;
   }
   */

- (void)mouseDown:(struct __GSEvent *)event {
	CGPoint clicked = GSEventGetLocationInWindow(event);
	_MouseDownX = clicked.x;
	_MouseDownY = clicked.y;
	GSLog(@"MouseDown");
	[super mouseDown:event];
}
- (void)mouseUp:(struct __GSEvent *)event {
	/*************
	 * NOTE: THE GSEVENTGETLOCATIONINWINDOW INVOCATION
	 * WILL NOT COMPILE UNLESS YOU HAVE PATCHED GRAPHICSSERVICES.H TO ALLOW IT!
	 * A patch is included in the svn.
	 *****************/

	CGPoint clicked = GSEventGetLocationInWindow(event);
	//BCC: swipe detection
	BOOL lChangeChapter = NO;
	if (clicked.y - _MouseDownY < 20 && clicked.y - _MouseDownY > -20)
	{
		if (clicked.x - _MouseDownX > 100 )
		{
			if ([_heartbeatDelegate respondsToSelector:@selector(chapForward:)]) 
					   [_heartbeatDelegate chapForward:(UINavBarButton*)nil];
			lChangeChapter = YES;
		}
		else if (clicked.x - _MouseDownX < -100)
		{
			if ([_heartbeatDelegate respondsToSelector:@selector(chapBack:)]) 
						  [_heartbeatDelegate chapBack:(UINavBarButton*)nil];
			lChangeChapter = YES;
		}
	}

	struct CGRect newRect = [self visibleRect];
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	int lZoneHeight = [defaults enlargeNavZone] ? 75 : 48;
	//GSLog(@"zone height %d", lZoneHeight);
	struct CGRect topTapRect = CGRectMake(0, 0, newRect.size.width, lZoneHeight);
	struct CGRect botTapRect = CGRectMake(0, contentRect.size.height - lZoneHeight, contentRect.size.width, lZoneHeight);
	if (!lChangeChapter && [self isScrolling]) {
		if (CGRectEqualToRect(lastVisibleRect, newRect)) {
			if (CGRectContainsPoint(topTapRect, clicked)) {
				if ([defaults inverseNavZone]) {
					//scroll forward one screen...
					[self pageDownWithTopBar:![defaults navbar] bottomBar:NO];
				} else {
					//scroll back one screen...
					[self pageUpWithTopBar:NO bottomBar:![defaults toolbar]];
				}
			} else if (CGRectContainsPoint(botTapRect,clicked)) {
				if ([defaults inverseNavZone]) {
					//scroll back one screen...
					[self pageUpWithTopBar:NO bottomBar:![defaults toolbar]];
				} else {
					//scroll forward one screen...
					[self pageDownWithTopBar:![defaults navbar] bottomBar:NO];
				}
			} else {  // If the old rect equals the new, then we must not be scrolling
				[self toggleNavbars];
			}
		}
		else
		{ //we are, in fact, scrolling
			[self hideNavbars];
		}
	}

	BOOL unused = [self releaseRubberBandIfNecessary];
	lastVisibleRect = [self visibleRect];
	GSLog(@"MouseUp");
	[super mouseUp:event];
}

// These two are so the toolbar buttons work!
// BUT: The the amount of the scroll needs to be adjusted based on the
// the defaults for showing the NAVBAR and TOOLBAR.
// Right now it scrolls based on full screen and thus, to far. Zach?
// FIXED: I think.
 // TODO: Adjust the bottom and top buffers.  The scrolling works, but
 // the text can wind up behind the toolbars at the bottom & top
 // of the text.
- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar
{
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	float  scrollness = contentRect.size.height;
	scrollness -= (((hasTopBar) ? 48 : 0) + ((hasBotBar) ? 48 : 0));
	scrollness /= size;
	scrollness = floor(scrollness - 1.0f);
	scrollness *= size;
	// That little dance above was so we only scroll in
	// multiples of the text size.  And it doesn't even work!
	[self scrollByDelta:CGSizeMake(0, scrollness)	animated:YES];
	[self hideNavbars];
}

-(void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar
{
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	float  scrollness = contentRect.size.height;
	scrollness -= (((hasTopBar) ? 48 : 0) + ((hasBotBar) ? 48 : 0));
	scrollness /= size;
	scrollness = floor(scrollness - 1.0f);
	scrollness *= size;
	// That little dance above was so we only scroll in
	// multiples of the text size.  And it doesn't even work!
	[self scrollByDelta:CGSizeMake(0, -scrollness) animated:YES];
	[self hideNavbars];
}

- (int)textSize
// This method is needed because the toolchain doesn't
// currently handle floating-point return values in an
// ARM-friendly way.
{
	return (int)size;
}

- (void)setTextSize:(int)newSize
{
	size = (float)newSize;
	[super setTextSize:size];
}

- (void)scrollSpeedDidChange:(NSNotification *)aNotification
{
	switch ([defaults scrollSpeedIndex])
	{
		case 0:
	  [self setScrollToPointAnimationDuration:0.75];
	  break;
		case 1:
	  [self setScrollToPointAnimationDuration:0.25];
	  break;
		case 2:
	  [self setScrollToPointAnimationDuration:0.0];
	  break;
	}
}

#pragma mark File Reading Methods START

//USE WITH CAUTION!!!!
- (void)setCurrentPathWithoutLoading:(NSString *)thePath {
	[thePath retain];
	[path release];
	path = thePath;
}

/**
 * Master method to load book - all others delegate here.
 *
 * @param thePath full file/path of book to load
 * @param numChars number of characters if known, -1 if not
 * @param didLoadAll pointer to bool which will return YES if the entire file was loaded into memory
 * @param theSubchapter subchapter number for chaptered HTML
 */
- (void)loadBookWithPath:(NSString *)thePath subchapter:(int)theSubchapter {
	NSMutableString *theHTML = nil;
	//GSLog(@"path: %@", thePath);

	[thePath retain];
	[path release];
	path = thePath;

	NSString *pathExt = [[thePath pathExtension] lowercaseString];

	BOOL bIsHtml;

	if ([pathExt isEqualToString:@"txt"]) {
		bIsHtml = NO;
		theHTML = [self readTextFile:thePath];
	} else if ([pathExt isEqualToString:@"html"] || [pathExt isEqualToString:@"htm"]) {
		bIsHtml = YES;
		theHTML = [self readHtmlFile:thePath];
	}	else if ([pathExt isEqualToString:@"pdb"]) { 
		// This could be PalmDOC, Plucker, iSilo, Mobidoc, or something completely different
		NSString *retType = nil;
		NSString *retObject = nil;
		NSObject *ret;

		ret = ReadPDBFile(thePath, &retType, &retObject);

		// Check the returned object and convert to string if necessary.
		if([@"DATA" isEqualToString:retObject]) {
			// Need to convert to string
			theHTML = [self convertPalmDoc:(NSData*)ret];
		} else {
			theHTML = (NSMutableString*)ret;
		}

		// Plain text types don't need to go through all the HTML conversion leg work.
		if([@"htm" isEqualToString:retType]) {
		  [HTMLFixer fixHTMLString:theHTML filePath:thePath imageOnly:YES];
		  bIsHtml = YES;
		} else {
			bIsHtml = NO;
		}
	}

  if(bIsHtml) {
    if ([defaults subchapteringEnabled] == NO) {
      [self setHTML:theHTML];
      subchapter = 0;
    } else {
      [chapteredHTML setHTML:theHTML];
      
      if (theSubchapter < [chapteredHTML chapterCount])
        subchapter = theSubchapter;
      else
        subchapter = 0;
      
      [self setHTML:[chapteredHTML getChapterHTML:subchapter]];
    }
  } else {
    [self setText:theHTML];
  }

	/* This code doesn't work.  Sorry, charlie.
	   if (1) //replace with a defaults check
	   { 
	   NSMutableString *ebookPath = [NSString  stringWithString:[BooksDefaultsController defaultEBookPath]];
	   NSString *styleSheetPath = [ebookPath stringByAppendingString:@"/style.css"];
	   if ([[NSFileManager defaultManager] fileExistsAtPath:styleSheetPath])
	   {
	   [[self _webView] setUserStyleSheetLocation:[NSURL fileURLWithPath:ebookPath]];
	   }
	//[ebookPath release];
	}
	*/
}

/**
 * Convert Palm data to string using proper text encoding.
 */
- (NSMutableString *)convertPalmDoc:(NSData*)p_data {
	NSMutableString *originalText;

	int i=0;
	NSStringEncoding encList[] = ENCODING_LIST;
	NSStringEncoding curEnc = encList[i];
	while(curEnc != -1) {
		GSLog(@"Trying encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
		originalText = [[NSMutableString alloc] initWithData:p_data encoding:curEnc];

		if(originalText != nil) {
			GSLog(@"Successfully opened with encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
			break;
		}

		curEnc = encList[++i];
	}

	if(originalText == nil) {
		originalText = [[NSMutableString alloc] initWithString:
			@"Could not determine text encoding.  Try changing the text encoding settings in Preferences.\n\n"];
	}

	return [originalText autorelease];  
}

/**
 * Read a text file, attempting to determine its encoding using defaults, automatically,
 * or with a list of common encodings, convert to HTML and return.
 */
- (NSMutableString *)readTextFile:(NSString *)file {  
	NSMutableString *originalText;

	int i=0;
	NSStringEncoding encList[] = ENCODING_LIST;
	NSStringEncoding curEnc = encList[i];
	while(curEnc != -1) {

		if(curEnc == AUTOMATIC_ENCODING) {
			GSLog(@"Trying automatic encoding");
			originalText = [[NSMutableString alloc] initWithContentsOfFile:file usedEncoding:&curEnc error:NULL];
		} else {
			GSLog(@"Trying encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
			originalText = [[NSMutableString alloc] initWithContentsOfFile:file encoding:curEnc error:NULL];
		}

		if(originalText != nil) {
			GSLog(@"Successfully opened with encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
			break;
		}

		curEnc = encList[++i];
	}

	if(originalText == nil) {
		originalText = [[NSMutableString alloc] initWithString:
			@"Could not determine text encoding.  Try changing the text encoding settings in Preferences.\n\n"];
	}

	return [originalText autorelease];  
}

/**
 * Reads and pre-processes an HTML file.
 *
 * This method reads the HTML as a text file (since that's what it is) to re-use the encoding
 * logic from readTextFile:.
 */
- (NSMutableString *)readHtmlFile:(NSString *)thePath {
	NSMutableString *originalText = [self readTextFile:thePath];
	[HTMLFixer fixHTMLString:originalText filePath:thePath imageOnly:NO];
	return originalText;
}

#pragma mark File Reading Methods END

/**
 * Toggle between white-on-black and black-on-white.
 */
- (void)invertText:(BOOL)b {
	if (b) {
		// makes the the view white text on black
		float backParts[4] = {0, 0, 0, 1};
		float textParts[4] = {1, 1, 1, 1};
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		[self setBackgroundColor: CGColorCreate( colorSpace, backParts)];
		[self setTextColor: CGColorCreate( colorSpace, textParts)];
		[self setScrollerIndicatorStyle:2];
	} else {
		float backParts[4] = {1, 1, 1, 1};
		float textParts[4] = {0, 0, 0, 1};
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		[self setBackgroundColor: CGColorCreate( colorSpace, backParts)];
		[self setTextColor: CGColorCreate( colorSpace, textParts)];
		[self setScrollerIndicatorStyle:0];
	}

	[self setNeedsDisplay];
}

/**
 * Cleanup.
 */
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[path release];
	[chapteredHTML release];
	[defaults release];
	[super dealloc];
}

/**
 * Get the currently displayed html chapter.
 */
- (int) getSubchapter {
	return subchapter;
}

/**
 * Get the count of html chapters.
 */
- (int) getMaxSubchapter {
	int maxSubchapter = 1;

	if ([defaults subchapteringEnabled] == YES)
		maxSubchapter = [chapteredHTML chapterCount];

	return maxSubchapter;
}

/**
 * Go to an explicit HTML chapter.
 */
- (void) setSubchapter: (int) chapter {
	CGPoint origin = { 0, 0 };

	if ([defaults subchapteringEnabled] && (subchapter < [chapteredHTML chapterCount])) {
		[self setHTML:[chapteredHTML getChapterHTML:subchapter]];
	}

	[self scrollPointVisibleAtTopLeft:origin];
	[self recalculateStyle];
	[self updateWebViewObjects];
	[self setNeedsDisplay];
}

/**
 * Go to the next HTML chapter.
 */
- (BOOL) gotoNextSubchapter {
	CGPoint origin = { 0, 0 };

	if ([defaults subchapteringEnabled] == NO)
		return NO;

	if ((subchapter + 1) >= [chapteredHTML chapterCount])
		return NO;

	[defaults setLastScrollPoint: [self visibleRect].origin.y
				   forSubchapter: subchapter
						 forFile: path];

	[self setHTML:[chapteredHTML getChapterHTML:++subchapter]];

	origin.y = [defaults lastScrollPointForFile:path inSubchapter:subchapter];
	[self scrollPointVisibleAtTopLeft:origin];
	[self setNeedsDisplay];
	return YES;
}

/**
 * Change to the previous HTML chapter.
 */
- (BOOL) gotoPreviousSubchapter {
	CGPoint origin = { 0, 0 };

	if ([defaults subchapteringEnabled] == NO)
		return NO;

	if (subchapter == 0)
		return NO;

	[defaults setLastScrollPoint: [self visibleRect].origin.y
				   forSubchapter: subchapter
						 forFile: path];

	[self setHTML:[chapteredHTML getChapterHTML:--subchapter]];

	origin.y = [defaults lastScrollPointForFile:path inSubchapter:subchapter];
	[self scrollPointVisibleAtTopLeft:origin];
	[self setNeedsDisplay];

	return YES;
}

/**
 * Redraw the screen.
 */
-(void) redraw {
	CGRect lWebViewFrame = [[self _webView] frame];
	CGRect lFrame = [self frame];
	//GSLog(@"lWebViewFrame :  x=%f, y=%f, w=%f, h=%f", lWebViewFrame.origin.x, lWebViewFrame.origin.y, lWebViewFrame.size.width, lWebViewFrame.size.height);
	//GSLog(@"lFrame : x=%f, y=%f, w=%f, h=%f", lFrame.origin.x, lFrame.origin.y, lFrame.size.width, lFrame.size.height);
	[[self _webView]setFrame: [self frame]];
	[self recalculateStyle];
	[self updateWebViewObjects];
	[self setNeedsDisplay];
}

- (int)  swipe: ( int)num  withEvent: ( struct __GSEvent *)event
{
	if (num == kUIViewSwipeLeft)
		GSLog(@"SwipeLeft");
	if (num == kUIViewSwipeRight)
		GSLog(@"SwipeRight");
}
- (BOOL)canHandleSwipes
{
	return YES;
}
@end
