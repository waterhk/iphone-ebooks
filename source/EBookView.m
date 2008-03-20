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

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UISliderControl.h>
#import <UIKit/UIAlphaAnimation.h>
#import <UIKit/UIProgressIndicator.h>
#import <UIKit/UIProgressHUD.h>
#import <UIKit/UIView-Gestures.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITextTraitsClientProtocol.h>
#import <UIKit/UIWebView.h>
#import <UIKit/UIViewTapInfo.h>
#import <UIKit/UIView-Geometry.h>

#import "HTMLFixer.h"
#import "EBookView.h"
#import "BooksDefaultsController.h"
#import "palm/palmconvert.h"
#import "ChapteredHTML.h"
#import "BoundsChangedNotification.h"

#define ENCODING_LIST {[defaults defaultTextEncoding], NSUTF8StringEncoding, NSISOLatin1StringEncoding, \
	NSWindowsCP1252StringEncoding, NSMacOSRomanStringEncoding,NSASCIIStringEncoding, -1}; 

@interface NSObject (HeartbeatDelegate)
- (void)showNavbars;
- (void)hideNavbars;
- (UIView*)progressParentView;
- (void)chapForward:(UINavBarButton *)button;
- (void)chapBack:(UINavBarButton *)button;
@end


@implementation EBookView

- (id)initWithFrame:(struct CGRect)rect delegate:(id)p_del parentView:(UIView*)p_par {
	if(self = [super initWithFrame:rect]) {
    chapteredHTML = [[ChapteredHTML alloc] init];
    subchapter    = 0;
    defaults      = [BooksDefaultsController sharedBooksDefaultsController]; 
    m_navBarsVisible = NO;
    m_readyToShow = NO;
    
    [self setAdjustForContentSizeChange:NO];
    [self setEditable:NO];

    [self setTextSize:16.0f];
    [self setTextFont:@"TimesNewRoman"];

    [self setAllowsRubberBanding:YES];
    [self setBottomBufferHeight:0.0f];

    [self scrollToMakeCaretVisible:NO];
    
    [self setScrollDecelerationFactor:0.996f];
    [self setTapDelegate:self];
    [self setScrollerIndicatorsPinToContent:NO];
    
    lastVisibleRect = [self visibleRect];
    [self scrollSpeedDidChange:nil];
    
    [self setDelegate:p_del];
    [self setupScrollerWithFrame:[self bounds] parent:p_par];
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                         selector:@selector(scrollSpeedDidChange:)
                           name:CHANGEDSCROLLSPEED
                           object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boundsDidChange:)
                                                 name:[BoundsChangedNotification didChangeName]
                                               object:nil];
  }
  
	return self;
}

/**
 * Setup the scroll slider.
 */
- (void)setupScrollerWithFrame:(struct CGRect)p_bounds parent:(UIView*)p_par {
  if(m_scrollerSlider == nil) {
    CGRect scrollerRect = CGRectMake(0, TOOLBAR_HEIGHT, p_bounds.size.width, TOOLBAR_HEIGHT);
    m_scrollerSlider = [[UISliderControl alloc] initWithFrame:scrollerRect];
    
    [p_par addSubview:m_scrollerSlider];
    float backParts[4] = {0, 0, 0, .5};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    [m_scrollerSlider setBackgroundColor: CGColorCreate( colorSpace, backParts)];
    [m_scrollerSlider addTarget:self action:@selector(handleSlider:) forEvents:7];
    [m_scrollerSlider setAlpha:0];
    
    UIImage *img = [UIImage applicationImageNamed:@"ReadIndicator.png"];
    [m_scrollerSlider setMinValueImage:img];
    [m_scrollerSlider setMaxValueImage:img];
    
    [self updateSliderPosition];
  }
}

/**
 * Notification when our bounds change - we probably rotated.
 */
- (void)boundsDidChange:(BoundsChangedNotification*)p_note {
  struct CGRect oldB = [p_note oldBounds];
  struct CGRect newB = [p_note newBounds];
  /*
  GSLog(@"EBookView changing from %f x %f @ (%f, %f) to %f x %f @ (%f, %f)",
        oldB.size.width, oldB.size.height, oldB.origin.x, oldB.origin.y,
        newB.size.width, newB.size.height, newB.origin.x, newB.origin.y
        );
*/
  [self setFrame:newB];
  if(newB.size.width <= newB.size.height) {
    // Portrait mode
    struct CGSize cSize = [[[self _webView] webView] contentSize];
    cSize.width = newB.size.width;
    [[[self _webView] webView] setContentSize:cSize];
//    [[self _webView]setFrame:[self bounds]];
//    [self recalculateStyle];
//    [self updateWebViewObjects];
//    [self webViewDidChange:nil];
//    [self setNeedsDisplay];
  }
//  
  //UIWebView *webV = [self _webView];
  
//  struct CGRect innerRect = [[webV webView] frame];
  //innerRect.size.width = newB.size.width;
  
    //[[[webV webView] mainFrame] reload:nil];

  //[webV layoutBeforeDraw]; // This lets us get wider on landscape, but not smaller on portrait.
/*
  id html = [[self HTML] retain];
  [self setHTML:html];
  [html release];
 */
  
  
  // Recreate the slider
  UIView *scrollParent = [[m_scrollerSlider superview] retain];
  [m_scrollerSlider removeFromSuperview];
  [m_scrollerSlider release];
  m_scrollerSlider = nil;
  [self setupScrollerWithFrame:newB parent:scrollParent];
  [scrollParent release];
    
  // Setup to fix the visibleRect
  [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(afterRotate) userInfo:nil repeats:NO];
}

/**
 * Update our visible rect once any rotations are done.
 */
- (void)afterRotate {
  // FIXME: This isn't working - we still have to double tap to scroll.
  lastVisibleRect = [self visibleRect];
  [self updateSliderPosition];
}


/**
 * Make sure our lastVisible gets updated after a scroll event.
 */
- (void)_scrollAnimationEnded {
  lastVisibleRect = [self visibleRect];
  [super _scrollAnimationEnded];
}

/**
 * Hide the nav bars and slider.
 */
- (void)hideNavbars {
  if(m_navBarsVisible) {
    [self hideSlider];
    if ([self delegate] != nil) {
      if ([[self delegate] respondsToSelector:@selector(hideNavbars)]) {
        [[self delegate] hideNavbars];
      }
    }
    m_navBarsVisible = NO;
  }
}

/**
 * Toggle visibility of the navbars and slider.
 */
- (void)toggleNavbars {
  if(m_navBarsVisible) {
    // Hide the navbars
    [self hideSlider];
    if ([self delegate] != nil) {
      if ([[self delegate] respondsToSelector:@selector(hideNavbars)]) {
        [[self delegate] hideNavbars];
      }
    }
    m_navBarsVisible = NO;
  } else {
    // Show the nav bars
    [self showSlider];
    if ([self delegate] != nil) {
      if ([[self delegate] respondsToSelector:@selector(showNavbars)]) {
        [[self delegate] showNavbars];
      }
    }
    m_navBarsVisible = YES;
  }
}

/**
 * Figure out where the scroller should be based on the currently visible portion of the document.
 */
- (void)updateSliderPosition {
  CGRect theWholeShebang = [[self _webView] frame];  
	CGRect lDefRect = [self bounds];
	CGRect visRect = [self visibleRect];
	int endPos = (int)theWholeShebang.size.height - lDefRect.size.height;
	[m_scrollerSlider setMinValue:0.0];
	[m_scrollerSlider setMaxValue:(float)endPos];
	[m_scrollerSlider setValue:visRect.origin.y];
}

/**
 * Show the scroll slider.
 */
- (void)showSlider {
  [self updateSliderPosition];
  [m_scrollerSlider setAlpha:1];
}

/**
 * Hide the scroll slider.
 */
- (void)hideSlider {
  [m_scrollerSlider setAlpha:0];
}

/**
 * React to a change in the slider position.
 */
- (void)handleSlider:(id)sender {
	if (m_scrollerSlider != nil) {
		CGPoint scrollness = CGPointMake(0, [m_scrollerSlider value]);
		[self scrollPointVisibleAtTopLeft:scrollness animated:NO];
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
	if ([self textSize] < MAX_FONT_SIZE) {
		struct CGRect oldRect = [self visibleRect];
		struct CGRect totalRect = [[self _webView] frame];
		float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
		float scrollFactor = middleRect / totalRect.size.height;
		[self setTextSize:[self textSize] + 2.0f];
           
    [self recalculateStyle];
    [self webViewDidChange:nil];
		[self setNeedsDisplay];
    
    totalRect = [[self _webView] frame];
		middleRect = scrollFactor * totalRect.size.height;
		oldRect.origin.y = middleRect - (oldRect.size.height / 2);
		[self scrollPointVisibleAtTopLeft:oldRect.origin animated:NO];
    
    [self updateSliderPosition];
	}
}

/**
 * Shrink on-screen text size.
 *
 * "What the f--- does ensmallen mean?" -- Zach Brewster-Geisz
 */
- (void)ensmallenText {
	if ([self textSize] > MIN_FONT_SIZE) {
		struct CGRect oldRect = [self visibleRect];
		struct CGRect totalRect = [[self _webView] frame];
		float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
		float scrollFactor = middleRect / totalRect.size.height;
 		[self setTextSize:[self textSize] - 2.0f];
    [self recalculateStyle];
    [self webViewDidChange:nil];
		[self setNeedsDisplay];
    
    totalRect = [[self _webView] frame];
		middleRect = scrollFactor * totalRect.size.height;
		oldRect.origin.y = middleRect - (oldRect.size.height / 2);
		[self scrollPointVisibleAtTopLeft:oldRect.origin animated:NO];
    
    [self updateSliderPosition];
	}
}

/**
 * Save the lastVisibleRect.
 *
 * This takes the place of a constant heartbeat, at least for purposes
 * of getting scrolling and tapping to work.
 */
- (void)mouseDown:(struct __GSEvent*)event {
	CGPoint clicked = GSEventGetLocationInWindow(event);
	//bcc first convert into the content view coordinates
	clicked = [self convertPoint:clicked fromView:nil];
	//bcc then translate to take into account the scroll amount
	CGPoint lOffset = [self offset];
	clicked.x -= lOffset.x;
	clicked.y -= lOffset.y;
	_MouseDownX = clicked.x ;
	_MouseDownY = clicked.y;
	[super mouseDown:event];
  lastVisibleRect = [self visibleRect];
}

/**
 * React to a mouseUp event.
 */
- (void)mouseUp:(struct __GSEvent *)event {
	CGPoint clicked = GSEventGetLocationInWindow(event);
	//bcc first convert into the content view coordinates
	clicked = [self convertPoint:clicked fromView:nil];
	//bcc then translate to take into account the scroll amount
	CGPoint lOffset = [self offset];
	clicked.x -= lOffset.x;
	clicked.y -= lOffset.y;
	//BCC: swipe detection
	BOOL lChangeChapter = NO;
	if (clicked.y - _MouseDownY < 20 && clicked.y - _MouseDownY > -20)
	{
		if (clicked.x - _MouseDownX > 100 )
		{
      [[self delegate] chapForward:nil];
			lChangeChapter = YES;
		}
		else if (clicked.x - _MouseDownX < -100)
		{
      [[self delegate] chapBack:nil];
			lChangeChapter = YES;
		}
	}

  if(!lChangeChapter) {
    struct CGRect newRect = [self visibleRect];
    struct CGRect contentRect = [self bounds];
    int lZoneHeight = [defaults enlargeNavZone] ? TOOLBAR_HEIGHT+30 : TOOLBAR_HEIGHT;

    struct CGRect topTapRect = CGRectMake(0, 0, newRect.size.width, lZoneHeight);
    struct CGRect botTapRect = CGRectMake(0, contentRect.size.height - lZoneHeight, contentRect.size.width, lZoneHeight);

    if ([self isScrolling]) {
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
      }	else {
        //we are, in fact, scrolling
        [self hideNavbars];
      }
    }
  }

  [self releaseRubberBandIfNecessary];
	lastVisibleRect = [self visibleRect];
	[super mouseUp:event];
}

/**
 * Scroll down one page of text.
 */
- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar {
	struct CGRect contentRect = [self bounds];
	float scrollness = contentRect.size.height;
	scrollness -= (((hasTopBar) ? TOOLBAR_HEIGHT : 0) + ((hasBotBar) ? TOOLBAR_HEIGHT : 0));
	scrollness /= [self textSize];
	scrollness = floor(scrollness - 1.0f);
	scrollness *= [self textSize];
	// That little dance above was so we only scroll in
	// multiples of the text size.  And it doesn't even work!
	[self scrollByDelta:CGSizeMake(0, scrollness)	animated:YES];
  
  [self updateSliderPosition];
	//[self hideNavbars];
}

/**
 * Scroll up one page of text.
 */
-(void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar {
	struct CGRect contentRect = [self bounds];
	float  scrollness = contentRect.size.height;
	scrollness -= (((hasTopBar) ? TOOLBAR_HEIGHT : 0) + ((hasBotBar) ? TOOLBAR_HEIGHT : 0));
	scrollness /= [self textSize];
	scrollness = floor(scrollness - 1.0f);
	scrollness *= [self textSize];
	// That little dance above was so we only scroll in
	// multiples of the text size.  And it doesn't even work!
	[self scrollByDelta:CGSizeMake(0, -scrollness) animated:YES];
  
  [self updateSliderPosition];
	//[self hideNavbars];
}

/**
 * React to change in scrolling speed.
 */
- (void)scrollSpeedDidChange:(NSNotification *)aNotification {
	switch ([defaults scrollSpeedIndex]) {
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

/**
 * Show the please wait / progress spinner view.
 */
- (void)showPleaseWait:(UIView*)p_parent {
  const int progHeight = 120;
  const int progWidth = 180;
  struct CGRect progRect = CGRectMake(([p_parent bounds].size.width - progWidth) / 2,
                                      ([p_parent bounds].size.height - progHeight) / 2,
                                      progWidth, 
                                      progHeight);
  
  m_progressIndicator = [[UIProgressHUD alloc] initWithFrame:progRect];
  [m_progressIndicator setText:@"Loading..."];
  [p_parent addSubview:m_progressIndicator];
  [m_progressIndicator show:YES];
}

/**
 * Hide the please wait / progress spinner view, apply book preferences.
 */
- (void)hidePleaseWait {
  [m_progressIndicator show:NO];
  [m_progressIndicator removeFromSuperview];
  [m_progressIndicator release];
  m_progressIndicator = nil;
  
  /*
   * This is a kludge for some weird threading issues.  We need to perform this from a timer on the main
   * thread in order for the scroll point to be updated.  I've tried numerous combinations of the various
   * thread and perform selector methods.  This seems to be the only one that works.  The navbar will
   * call this method once the flurry or transitions is done.  Then we schedule a timer on ourself
   * and all is well. -ZSB 16-Mar-2008
   */
  [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(applyPreferences) userInfo:nil repeats:NO];
}

/**
 * Return YES if content is loaded and we're ready to transition.
 */
- (BOOL)isReadyToShow {
  return m_readyToShow;
}

#pragma mark File Reading Methods START

/**
 * Set the book and chapter without loading.
 * Use for deferred loading with progress bars, etc.
 */
- (void)setBookPath:(NSString*)p_path subchapter:(int)p_chap {
  m_readyToShow = NO;
  [p_path retain];
  [path release];
  path = p_path;
  subchapter = p_chap;
  
  [defaults setLastSubchapter:p_chap forFile:p_path]; // Update 'read' indicator
}

/**
 * Actually load the book set with setBookPath:subchapter:.
 */
- (void)loadSetDocumentWithProgressOnView:(UIView*)p_progView {
  if(p_progView != nil) {
    [self showPleaseWait:p_progView];
    [NSThread detachNewThreadSelector:@selector(reallyLoadBook) toTarget:self withObject:nil];
  } else {
    [self loadBookWithPath:path subchapter:subchapter];
  }
}

/**
 * Call from main runloop so progres hud displays.
 */
- (void)reallyLoadBook {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [self loadBookWithPath:path subchapter:subchapter];
  [pool release];
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
  m_readyToShow = NO;
  GSLog(@"Loading book %@", thePath);
  
  // Update the 'read' indicator for the file browser
  [defaults setLastSubchapter:theSubchapter forFile:thePath];
  
	NSMutableString *theHTML = nil;
  
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
 
  m_readyToShow = YES;
  
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
    //GSLog(@"Trying encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
    originalText = [[NSMutableString alloc] initWithData:p_data encoding:curEnc];
    
    if(originalText != nil) {
      //GSLog(@"Successfully opened with encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
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
      //GSLog(@"Trying automatic encoding");
      originalText = [[NSMutableString alloc] initWithContentsOfFile:file usedEncoding:&curEnc error:NULL];
    } else {
      //GSLog(@"Trying encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
      originalText = [[NSMutableString alloc] initWithContentsOfFile:file encoding:curEnc error:NULL];
    }
    
    if(originalText != nil) {
      //GSLog(@"Successfully opened with encoding: %@", CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(curEnc)));
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
- (BOOL)setSubchapter:(int)chapter {
	if ([defaults subchapteringEnabled] && chapter >= 0 && (chapter < [chapteredHTML chapterCount])) {
    GSLog(@"Set subchapter to %d", chapter);
    subchapter = chapter;
    [self saveBookPosition];
		[self setHTML:[chapteredHTML getChapterHTML:subchapter]];
    [self scrollToPoint:[defaults lastScrollPointForFile:path inSubchapter:subchapter]];
    [self recalculateStyle];
    [self updateWebViewObjects];
    [self setNeedsDisplay]; 
    return YES;
	} else {
    return NO;
  }
}

/**
 * Go to the next HTML chapter.
 */
- (BOOL)gotoNextSubchapter {
  return [self setSubchapter:subchapter+1];
}

/**
 * Change to the previous HTML chapter.
 */
- (BOOL) gotoPreviousSubchapter {
  return [self setSubchapter:subchapter-1];
}

/*
- (int)  swipe: ( int)num  withEvent: ( struct __GSEvent *)event
{
	if (num == kUIViewSwipeLeft)
		GSLog(@"SwipeLeft");
	if (num == kUIViewSwipeRight)
		GSLog(@"SwipeRight");
}
*/

- (BOOL)canHandleSwipes
{
	return YES;
}

/**
 * Apply various defaults to the given EBookView.
 */
- (void)applyPreferences {
  [self setTextSize:[defaults textSize]];
  [self invertText:[defaults inverted]];
  [self setTextFont:[defaults textFont]];

  // FIXME: This toolbar/navbar stuff needs to react to hide/show
	if (![defaults navbar]) {
		[self setMarginTop:TOOLBAR_HEIGHT];
  } else {
		[self setMarginTop:0];
  }
  
	if (![defaults toolbar]) {
		[self setBottomBufferHeight:TOOLBAR_HEIGHT];
	} else {
		[self setBottomBufferHeight:0];
  }

  // Restore scroll location
  [self scrollToPoint:[defaults lastScrollPointForFile:path inSubchapter:subchapter]];
}

/**
 * Scrolls to the given point by waking up the heartbeat for one pulse.
 */
- (void)scrollToPoint:(float)p_pt {
//  GSLog(@"Scrolling book position to %f", p_pt);
  [self scrollPointVisibleAtTopLeft:CGPointMake(0.0f, p_pt) animated:NO];
}

/**
 * Save the current chapter and scroll point to preferences.
 */
- (void)saveBookPosition {
  if(path) {
    float pt = [self visibleRect].origin.y;
//    GSLog(@"EBookView saving position %f for book %@", pt, path);
    [defaults setLastScrollPoint:pt
                   forSubchapter:[self getSubchapter]
                         forFile:[self currentPath]];
    [defaults setLastSubchapter:subchapter forFile:[self currentPath]];
  }
}

/**
 * Cleanup.
 */
- (void)dealloc {
  GSLog(@"Book dealloc");
  [self saveBookPosition];
  
	[[NSNotificationCenter defaultCenter] removeObserver:self];
 
  [m_progressIndicator removeFromSuperview];  
  [m_progressIndicator release];

  [m_scrollerSlider removeFromSuperview];
  [m_scrollerSlider release];
	
  [path release];
	[chapteredHTML release];
	[defaults release];
  
	[super dealloc];
}
@end
