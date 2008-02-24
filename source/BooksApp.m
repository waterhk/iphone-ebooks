/* ------ BooksApp, written by Zachary Brewster-Geisz
   (and others)
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

#import "BooksApp.h"
#import "PreferencesController.h"
#import <UIKit/UIView-Geometry.h>
//#include "dolog.h"
#include <stdio.h>
@implementation BooksApp
/*
   enum {
   kFACEUP = 0,
   kNORMAL = 1,
   kUPSIDEDOWN = 2,
   kLANDL = 3,
   kLANDR = 4,
   kFACEDOWN = 6
   };
   */
- (void) applicationDidFinishLaunching: (id) unused
{
	freopen("/var/logs/Books.traces", "w", stderr);
	//investigate using [self setUIOrientation 3] that may alleviate for the need of a weirdly sized window
	NSString *recentFile;
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	//bcc rect to change for rotate90

	struct CGRect rect = 	[defaults fullScreenApplicationContentRect];

	doneLaunching = NO;

	transitionHasBeenCalled = NO;

	navbarsAreOn = YES;

	textViewNeedsFullText = NO;
	imageSplashed = NO;

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateToolbar:)
												 name:@"toolbarDefaultsChanged"
											   object:nil];

	window = [[UIWindow alloc] initWithContentRect: rect];

	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];
	struct CGSize progsize = [UIProgressIndicator defaultSizeForStyle:0];
	//Bcc: this positioning should be relative to the screen rect not to some arbitrary value
	//based on the size of the current gen iphone
	progressIndicator = [[UIProgressIndicator alloc] 
		initWithFrame:CGRectMake((rect.size.width-progsize.width)/2,
				(rect.size.height-progsize.height)/2,
				progsize.width, 
				progsize.height)];
	[progressIndicator setStyle:0];
	mainView = [[UIView alloc] initWithFrame: rect];

	[self setupNavbar];
	[self setupToolbar];

	textView = [[EBookView alloc] 
		initWithFrame:
		CGRectMake(0, 0, rect.size.width, rect.size.height)];

	[self refreshTextViewFromDefaults];


	recentFile = [defaults fileBeingRead];
	readingText = [defaults readingText];


	transitionView = [[UITransitionView alloc] initWithFrame:
		CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)];

	[window setContentView: mainView];
	//bcc rotation
	[self rotateApp];
	[mainView addSubview:transitionView];
	[mainView addSubview:navBar];
	[mainView addSubview:bottomNavBar];
	if (!readingText) 
		[bottomNavBar hide:YES];

	[textView setHeartbeatDelegate:self];

	[navBar setTransitionView:transitionView];
	[transitionView setDelegate:self];

	NSString *coverart = [EBookImageView coverArtForBookPath:[defaults lastBrowserPath]];
	imageSplashed = !(nil == coverart);
	if (!imageSplashed)
	{
		coverart = [[NSBundle mainBundle] pathForResource:@"Default"
												   ofType:@"png"];
		[progressIndicator setStyle:![defaults inverted]];
	}
	imageView = [[EBookImageView alloc] initWithContentsOfFile:coverart withinSize:rect.size];
	[mainView addSubview:imageView];
	[mainView addSubview:progressIndicator];
	[progressIndicator startAnimation];

	/// FIXME just a test.
	/*
	   NSStringEncoding *enclist = malloc(500*sizeof(NSStringEncoding));
	   enclist = [NSString availableStringEncodings];
	   while (*enclist != 0)
	   {
	   GSLog(@"%u, %@",*enclist, [NSString localizedNameOfStringEncoding:*(enclist++)]);
	   }
	   free(enclist);
	   */
}


- (void)finishUpLaunch
{
	NSString *recentFile = [defaults fileBeingRead];
	
	if (imageSplashed)
	{
		[self _dumpScreenContents:nil];
	//	NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"Default"
	//															ofType:@"png"];
		NSString * lPath = [NSHomeDirectory() stringByAppendingPathComponent:LIBRARY_PATH];
		if (![[NSFileManager defaultManager] fileExistsAtPath: lPath])
			[[NSFileManager defaultManager] createDirectoryAtPath:lPath attributes:nil];
		NSString *defaultPath = [NSHomeDirectory() stringByAppendingPathComponent:DEFAULT_REAL_PATH];
		NSData *nsdat = [NSData dataWithContentsOfFile:@"/tmp/foo_0.png"];
		[nsdat writeToFile:defaultPath atomically:YES];
		imageSplashed = NO;
	}
	UINavigationItem *tempItem = [[UINavigationItem alloc] initWithTitle:@"Books"];
	[navBar pushNavigationItem:tempItem withBrowserPath:[BooksDefaultsController defaultEBookPath]];

	NSString *tempString = [defaults lastBrowserPath];
	NSMutableArray *tempArray = [[NSMutableArray alloc] init]; 

	if (![tempString isEqualToString:[BooksDefaultsController defaultEBookPath]])
	{
		[tempArray addObject:[NSString stringWithString:tempString]];
		while ((![(tempString = [tempString stringByDeletingLastPathComponent])
					isEqualToString:[BooksDefaultsController defaultEBookPath]]) && 
	  (![tempString isEqualToString:@"/"])) //sanity check
		{
			[tempArray addObject:[NSString stringWithString:tempString]];
		} // while
	} // if

	NSEnumerator *pathEnum = [tempArray reverseObjectEnumerator];
	NSString *curPath;  
	while (nil != (curPath = [pathEnum nextObject]))
	{
		UINavigationItem *tempItem = [[UINavigationItem alloc]
			initWithTitle:[curPath lastPathComponent]];
		[navBar pushNavigationItem:tempItem withBrowserPath:curPath];
		[tempItem release];
	}

	if (readingText)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile])
		{

			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[recentFile lastPathComponent] 
				stringByDeletingPathExtension]];
			int subchapter = [defaults lastSubchapterForFile:recentFile];
			float scrollPoint = (float) [defaults lastScrollPointForFile:recentFile
															inSubchapter:subchapter];

			[navBar pushNavigationItem:tempItem withView:textView];
			[textView loadBookWithPath:recentFile subchapter:subchapter];
			textViewNeedsFullText = NO;
			[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
										 animated:NO];
			[tempItem release];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		}
		else
		{  // Recent file has been deleted!  RESET!
			readingText = NO;
			[defaults setReadingText:NO];
			[defaults setFileBeingRead:@""];
			[defaults setLastBrowserPath:[BooksDefaultsController defaultEBookPath]];
			[defaults removePerFileDataForFile:recentFile];
		}
	}

	imageSplashed = NO;
	transitionHasBeenCalled = YES;


	[tempArray release];

	[navBar enableAnimation];
	[progressIndicator stopAnimation];
	[progressIndicator removeFromSuperview];
	[imageView removeFromSuperview];
	[imageView release];
	imageView = nil;
}

- (void)heartbeatCallback:(id)unused
{
	if (!doneLaunching)
	{
		[self finishUpLaunch];
		doneLaunching = YES;
	}
	if ((textViewNeedsFullText) && ![transitionView isTransitioning])
	{
		[textView loadBookWithPath:[textView currentPath] subchapter:[defaults lastSubchapterForFile:[textView currentPath]]];
		textViewNeedsFullText = NO;
	}
	if ((!transitionHasBeenCalled)/* && ![transitionView isTransitioning]*/)
	{
		if ((textView != nil) && (defaults != nil))
		{
			//[self refreshTextViewFromDefaults];
		}
	}
}

- (void)hideNavbars
{
	GSLog(@"hideNavbars");
	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[textView setFrame:rect];
	[navBar hide:NO];
	[bottomNavBar hide:NO];
	[self hideSlider];
}

- (void)toggleNavbars
{
	GSLog(@"toggleNavbars");
	[navBar toggle];
	[bottomNavBar toggle];
	if (nil == scrollerSlider)
		[self showSlider:true];
	else
		[self hideSlider];
}

- (void)showSlider:(BOOL)withAnimation
{
	GSLog(@"showSlider");
	CGRect rect = CGRectMake(0, 48, [defaults fullScreenApplicationContentRect].size.width, 48);
	CGRect lDefRect = [defaults fullScreenApplicationContentRect];
	if (nil != scrollerSlider)
	{
		[scrollerSlider removeFromSuperview];
		[scrollerSlider autorelease];
		scrollerSlider = nil;
	}
	else
	{
	}
	scrollerSlider = [[UISliderControl alloc] initWithFrame:rect];
	[mainView addSubview:scrollerSlider];
	CGRect theWholeShebang = [[textView _webView] frame];
	CGRect visRect = [textView visibleRect];
	//GSLog(@"visRect: x=%f, y=%f, w=%f, h=%f", visRect.origin.x, visRect.origin.y, visRect.size.width, visRect.size.height);
	//GSLog(@"theWholeShebang: x=%f, y=%f, w=%f, h=%f", theWholeShebang.origin.x, theWholeShebang.origin.y, theWholeShebang.size.width, theWholeShebang.size.height);
	int endPos = (int)theWholeShebang.size.height - lDefRect.size.height;
	[scrollerSlider setMinValue:0.0];
	[scrollerSlider setMaxValue:(float)endPos];
	[scrollerSlider setValue:visRect.origin.y];
	float backParts[4] = {0, 0, 0, .5};
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	[scrollerSlider setBackgroundColor: CGColorCreate( colorSpace, backParts)];
	[scrollerSlider addTarget:self action:@selector(handleSlider:) forEvents:7];
	[scrollerSlider setAlpha:0];
	//  [scrollerSlider setShowValue:YES];
	UIImage *img = [UIImage applicationImageNamed:@"ReadIndicator.png"];
	[scrollerSlider setMinValueImage:img];
	[scrollerSlider setMaxValueImage:img];
	if (withAnimation)
	{
		if (animator != nil)
			[animator release];
		animator = [[UIAnimator alloc] init];
		if (alpha != nil)
			[alpha release];
		alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
		[alpha setStartAlpha:0];
		[alpha setEndAlpha:1];
		[animator addAnimation:alpha withDuration:0.25 start:YES];
	}
	else
	{
		[scrollerSlider setAlpha:1];
	}

	//[animator autorelease];
	//[alpha autorelease];
}

- (void)hideSlider
{
	if (scrollerSlider != nil)
	{
		if (animator != nil)
			[animator release];
		animator = [[UIAnimator alloc] init];
		if (alpha != nil)
			[alpha release];
		alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
		[alpha setStartAlpha:1];
		[alpha setEndAlpha:0];
		[animator addAnimation:alpha withDuration:0.1 start:YES];
		[scrollerSlider release];
		scrollerSlider = nil;
	}
}

- (void)handleSlider:(id)sender
{
	if (scrollerSlider != nil)
	{
		CGPoint scrollness = CGPointMake(0, [scrollerSlider value]);
		[textView scrollPointVisibleAtTopLeft:scrollness animated:NO];
	}
}

- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file 
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if ([fileManager fileExistsAtPath:file isDirectory:&isDir] && isDir)
	{
		UINavigationItem *tempItem = [[UINavigationItem alloc]
			initWithTitle:[file lastPathComponent]];
		[navBar pushNavigationItem:tempItem withBrowserPath:file];
		[tempItem release];
	}
	else // not a directory
	{
		BOOL sameFile;
		NSString *ext = [file pathExtension];
		BOOL isPicture = ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"]);
		if (isPicture)
		{
			if (nil != imageView)
				[imageView release];
			imageView = [[EBookImageView alloc] initWithContentsOfFile:file];
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			[defaults removePerFileDataForFile:file];
			[navBar pushNavigationItem:tempItem withView:imageView];
			[tempItem release];
		}
		else //text or HTML file
		{
			readingText = YES;
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			sameFile = [[textView currentPath] isEqualToString:file];
			[navBar pushNavigationItem:tempItem withView:textView];
			if (!sameFile)
				// Slight optimization.  If the file is already loaded,
				// don't bother reloading.
			{
				int subchapter = [defaults lastSubchapterForFile:file];
				float scrollPoint = (float) [defaults lastScrollPointForFile:file
																inSubchapter:subchapter];
				BOOL didLoadAll = NO;
				CGRect rect = [defaults fullScreenApplicationContentRect];
				int numScreens = ((int) scrollPoint / rect.size.height) + 1;  // how many screens down are we?
				int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));

				[textView loadBookWithPath:file
							 numCharacters:numChars
								didLoadAll:&didLoadAll
								subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
											 animated:NO];
				textViewNeedsFullText = !didLoadAll;
			}

			[tempItem release];
		}
		if (isPicture)
		{
			[navBar show];
			[bottomNavBar hide:YES];
		}
		else
		{
			[navBar hide:NO];
			if (![defaults toolbar])
				[bottomNavBar show];
			else
				[bottomNavBar hide:NO];
		}
	}
}

- (void)textViewDidGoAway:(id)sender
{
	//  GSLog(@"textViewDidGoAway start...");
	struct CGRect  selectionRect = [textView visibleRect];
	int            subchapter    = [textView getSubchapter];
	NSString      *filename      = [textView currentPath];
	//  GSLog(@"called visiblerect, origin.y is %d ", (unsigned int)selectionRect.origin.y);

	[defaults setLastScrollPoint: (unsigned int) selectionRect.origin.y
				   forSubchapter:subchapter
						 forFile:filename];
	[defaults setLastSubchapter:subchapter forFile:filename];
	//  GSLog(@"set defaults ");
	[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
														object:[textView currentPath]];

	readingText = NO;
	[bottomNavBar hide:YES];
	if (scrollerSlider != nil)
		[self hideSlider];
	//  GSLog(@"end.\n");
}

- (void)cleanUpBeforeQuit
{
	if (!readingText ||
			(nil == [EBookImageView coverArtForBookPath:[textView currentPath]]))
	{
		NSData *defaultData;
		NSString * lPath = [NSHomeDirectory() stringByAppendingPathComponent:LIBRARY_PATH];
		if (![[NSFileManager defaultManager] fileExistsAtPath: lPath])
			[[NSFileManager defaultManager] createDirectoryAtPath:lPath attributes:nil];
		if ([defaults inverted])
		{
			defaultData = [NSData dataWithContentsOfFile:
				  [[NSBundle mainBundle] pathForResource:@"Default_dark"
												  ofType:@"png"]];
		}
		else
		{
			defaultData = [NSData dataWithContentsOfFile:
				  [[NSBundle mainBundle] pathForResource:@"Default_light"
												  ofType:@"png"]];
		}
		NSString *defaultPath = [NSHomeDirectory() stringByAppendingPathComponent:DEFAULT_REAL_PATH];
		[defaultData writeToFile:defaultPath atomically:YES];
	}
	struct CGRect  selectionRect;
	int            subchapter = [textView getSubchapter];
	NSString      *filename   = [textView currentPath];

	[defaults setFileBeingRead:filename];
	selectionRect = [textView visibleRect];
	[defaults setLastScrollPoint: (unsigned int)selectionRect.origin.y
				   forSubchapter: subchapter
						 forFile: filename];
	[defaults setLastSubchapter:subchapter forFile:filename];
	[defaults setReadingText:readingText];
	[defaults setLastBrowserPath:[navBar topBrowserPath]];
	[defaults synchronize];
}

- (void) applicationWillSuspend
{
	[self cleanUpBeforeQuit];
}

- (void)applicationWillTerminate
{
	[self cleanUpBeforeQuit];
}

- (void)embiggenText:(UINavBarButton *)button
{
	if (![button isPressed]) // mouse up events only, kids!
	{
		CGRect rect = [[textView _webView] frame];
		[textView embiggenText];
		if (scrollerSlider != nil)
		{
			float maxval = rect.size.height;
			float val = [scrollerSlider value];
			float percentage = val / maxval;
			rect = [[textView _webView] frame];
			[scrollerSlider setMaxValue:rect.size.height];
			[scrollerSlider setValue:(rect.size.height * percentage)];
		}
		[defaults setTextSize:[textView textSize]];
	}
}

- (void)ensmallenText:(UINavBarButton *)button
{
	if (![button isPressed]) // mouse up events only, kids!
	{
		CGRect rect = [[textView _webView] frame];
		[textView ensmallenText];
		if (scrollerSlider != nil)
		{
			float maxval = rect.size.height;
			float val = [scrollerSlider value];
			float percentage = val / maxval;
			rect = [[textView _webView] frame];
			[scrollerSlider setMaxValue:rect.size.height];
			//[scrollerSlider setValue:oldRect.origin.y];
			[scrollerSlider setValue:(rect.size.height * percentage)];
		}
		[defaults setTextSize:[textView textSize]];
	}
}

- (void)invertText:(UINavBarButton *)button 
{
	if (![button isPressed]) // mouse up events only, kids!
	{
		textInverted = !textInverted;
		[textView invertText:textInverted];
		[defaults setInverted:textInverted];
		[self toggleStatusBarColor];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		[textView setFrame:rect];
	}	
}

- (void)pageDown:(UINavBarButton *)button 
{
	if (![button isPressed])
	{
		[textView pageDownWithTopBar:![defaults navbar]
						   bottomBar:![defaults toolbar]];
	}	
}

- (void)pageUp:(UINavBarButton *)button 
{
	if (![button isPressed])
	{
		[textView pageUpWithTopBar:![defaults navbar]
						 bottomBar:![defaults toolbar]];
	}	
}

- (void)chapForward:(UINavBarButton *)button 
{
	GSLog(@"chapForward start");
	if (![button isPressed])
	{
		if ([textView gotoNextSubchapter] == YES)
		{
			/*
			   CGRect frame    = [[textView _webView] frame];
			   CGRect viewable = [textView visibleRect];
			   float endPos    = frame.size.height - viewable.size.height;
			   [scrollerSlider setMinValue:0.0];
			   [scrollerSlider setMaxValue:endPos];
			   [scrollerSlider setValue:viewable.origin.y];
			   */ // that dance isn't needed if we just hide the slider :)
			[self hideSlider];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		}
		else
		{
			NSString *nextFile = [[navBar topBrowser] fileAfterFileNamed:[textView currentPath]];
			if ((nil != nextFile) && [nextFile isReadableTextFilePath])
			{
				[self hideSlider];
				EBookView *tempView = textView;
				struct CGRect visRect = [tempView visibleRect];
				int            subchapter = [tempView getSubchapter];
				NSString      *filename   = [tempView currentPath];

				[defaults setLastScrollPoint:(unsigned int)visRect.origin.y
							   forSubchapter:subchapter
									 forFile:filename];
				[defaults setLastSubchapter:subchapter forFile:filename];

				[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
																	object:[tempView currentPath]];
//				[textView autorelease];
				textView = [[EBookView alloc] initWithFrame:[tempView frame]];
				[textView setHeartbeatDelegate:self];

				UINavigationItem *tempItem = 
					[[UINavigationItem alloc] initWithTitle:
					[[nextFile lastPathComponent] 
					stringByDeletingPathExtension]];
				[navBar pushNavigationItem:tempItem withView:textView];
				[self refreshTextViewFromDefaults];

				subchapter = [defaults lastSubchapterForFile:nextFile];
				int lastPt = [defaults lastScrollPointForFile:nextFile inSubchapter:subchapter]; BOOL didLoadAll = NO; 
				CGRect rect = [defaults fullScreenApplicationContentRect];
				int numScreens = (lastPt / rect.size.height) + 1;  // how many screens down are we?  
				int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));  //bcc I wonder what is 265000 but it has to be replaced
				[textView loadBookWithPath:nextFile numCharacters:numChars
								didLoadAll:&didLoadAll subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, (float) lastPt)
											 animated:NO];
				textViewNeedsFullText = !didLoadAll;
				[tempItem release];
				[tempView autorelease];
			}
		}
	}	

	GSLog(@"chapForward end");
}

- (void)chapBack:(UINavBarButton *)button 
{
	if (![button isPressed])
	{
		if ([textView gotoPreviousSubchapter] == YES)
		{
			/*
			   CGRect frame    = [[textView _webView] frame];
			   CGRect viewable = [textView visibleRect];
			   float endPos    = frame.size.height - viewable.size.height;
			   [scrollerSlider setMinValue:0.0];
			   [scrollerSlider setMaxValue:endPos];
			   [scrollerSlider setValue:viewable.origin.y];
			   */ // that dance isn't needed if we just hide the slider :)
			[self hideSlider];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		}

		else
		{
			NSString *prevFile = [[navBar topBrowser] fileBeforeFileNamed:[textView currentPath]];
			if ((nil != prevFile) && [prevFile isReadableTextFilePath])
			{
				[self hideSlider];
				EBookView *tempView = textView;
				struct CGRect visRect = [tempView visibleRect];
				int            subchapter = [tempView getSubchapter];
				NSString      *filename   = [tempView currentPath];

				[defaults setLastScrollPoint: (unsigned int) visRect.origin.y
							   forSubchapter: subchapter
									 forFile: filename];
				[defaults setLastSubchapter:subchapter forFile:filename];

				[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
																	object:[tempView currentPath]];
				textView = [[EBookView alloc] initWithFrame:[tempView frame]];
				[textView setHeartbeatDelegate:self];
				UINavigationItem *tempItem = 
					[[UINavigationItem alloc] initWithTitle:
					[[prevFile lastPathComponent] 
					stringByDeletingPathExtension]];

				[navBar pushNavigationItem:tempItem withView:textView reverseTransition:YES];
				[self refreshTextViewFromDefaults];
				//[progressHUD show:YES];

				subchapter = [defaults lastSubchapterForFile:prevFile];
				int lastPt = [defaults lastScrollPointForFile:prevFile
												 inSubchapter:subchapter];
				[textView loadBookWithPath:prevFile subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, (float) lastPt)
											 animated:NO];
				//[progressHUD show:NO];
				[tempItem release];
				[tempView autorelease];
			}
		}
	}	
}

// CHANGED: Moved navbar and toolbar setup here from applicationDidFinishLaunching

- (void)setupNavbar
{

	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[navBar release]; //BCC in case this is not the first time this method is called
	navBar = [[HideableNavBar alloc] initWithFrame:
		CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];

	[navBar setDelegate:self];
	[navBar setBrowserDelegate:self];
	[navBar setExtensions:[NSArray arrayWithObjects:@"txt", @"htm", @"html", @"pdb", @"jpg", @"png", @"gif", nil]];
	[navBar hideButtons];

	[navBar disableAnimation];
	float lMargin = 45.0f;
	[navBar setRightMargin:lMargin];
	//position the prefsButton in the margin
	//for some reason cannot click on the button when it is there
	prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(rect.size.width-lMargin,9,40,30) selector:@selector(showPrefs:) flipped:NO];
	//prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(275,9,40,30) selector:@selector(showPrefs:) flipped:NO];

	[navBar addSubview:prefsButton];
}

- (void)setupToolbar
{
	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[bottomNavBar release]; //BCC in case this is not the first time this method is called
	bottomNavBar = [[HideableNavBar alloc] initWithFrame:
		CGRectMake(rect.origin.x, rect.size.height - 48.0f, 
				rect.size.width, 48.0f)];

	[bottomNavBar setBarStyle:0];
	[bottomNavBar setDelegate:self];

	if ([defaults flipped]) {
		downButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(5,9,40,30) selector:@selector(pageDown:) flipped:YES];
		upButton = [self toolbarButtonWithName:@"up" rect:CGRectMake(45,9,40,30) selector:@selector(pageUp:) flipped:YES];

		if (![defaults pagenav]) { // If pagnav buttons should be off, then move the chapter buttons over
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(5,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(45,9,40,30) selector:@selector(chapForward:) flipped:NO];
		} else {
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(88,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(128,9,40,30) selector:@selector(chapForward:) flipped:NO];	
		}

		rotateButton = [self toolbarButtonWithName:@"rotate" rect:CGRectMake(171,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(203,9,30,30) selector:@selector(invertText:) flipped:NO];
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(235,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(275,9,40,30) selector:@selector(embiggenText:) flipped:NO];
	} else {
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(5,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(45,9,40,30) selector:@selector(embiggenText:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(87,9,30,30) selector:@selector(invertText:) flipped:NO];
		rotateButton = [self toolbarButtonWithName:@"rotate" rect:CGRectMake(119,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];

		if (![defaults pagenav]) { // If pagnav buttons should be off, then move the chapter buttons over
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(235,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(275,9,40,30) selector:@selector(chapForward:) flipped:NO];
		} else {
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(152,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(192,9,40,30) selector:@selector(chapForward:) flipped:NO];
		}

		upButton = [self toolbarButtonWithName:@"up" rect:CGRectMake(235,9,40,30) selector:@selector(pageUp:) flipped:NO];
		downButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(275,9,40,30) selector:@selector(pageDown:) flipped:NO];
	}

	[bottomNavBar addSubview:minusButton];
	[bottomNavBar addSubview:plusButton];
	[bottomNavBar addSubview:invertButton];
	[bottomNavBar addSubview:rotateButton];

	if ([defaults chapternav]) {
		[bottomNavBar addSubview:leftButton];
		[bottomNavBar addSubview:rightButton];
	}
	if ([defaults pagenav]) {	
		[bottomNavBar addSubview:upButton];
		[bottomNavBar addSubview:downButton];
	}
}

- (UINavBarButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped 
{
	UINavBarButton	*button = [[UINavBarButton alloc] initWithFrame:rect];

	[button setAutosizesToFit:NO];
	[button setImage:[self navBarImage:[NSString stringWithFormat:@"%@_up",name] flipped:flipped] forState:0];
	[button setImage:[self navBarImage:[NSString stringWithFormat:@"%@_down",name] flipped:flipped] forState:1];
	[button setDrawContentsCentered:YES];
	[button addTarget:self action:selector forEvents: (255)];
	[button setNavBarButtonStyle:0];
	//bcc this complains about an invalid context, it seems to work fine without anyway
	//	[button drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
	[button setEnabled:YES];
	return button;
}

- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped
{
	NSBundle *bundle = [NSBundle mainBundle];
	imgPath = [bundle pathForResource:name ofType:@"png"];
	buttonImg = [[UIImage alloc]initWithContentsOfFile:imgPath];
	if (flipped) [buttonImg setOrientation:4];
	return buttonImg;
}

- (void)updateNavbar
{
	CGRect rect = [defaults fullScreenApplicationContentRect];
	[navBar setFrame: 	CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];
	float lMargin = 45.0f;
	[prefsButton setFrame:CGRectMake(rect.size.width-lMargin,9,40,30) ];
}

- (void)updateToolbar:(NSNotification *)notification
{
	GSLog(@"%s Got toolbar update notification.", _cmd);
	BOOL lBottomBarHidden = [bottomNavBar hidden];
	[bottomNavBar removeFromSuperview];
	[self setupToolbar];
	[mainView addSubview:bottomNavBar];
	if (lBottomBarHidden)
		[bottomNavBar hide:NO];
}

- (void)setTextInverted:(BOOL)b
{
	textInverted = b;
}

- (void)showPrefs:(UINavBarButton *)button
{
	if (![button isPressed]) // mouseUp only
	{
		GSLog(@"Showing Preferences View");
		PreferencesController *prefsController = [[PreferencesController alloc] initWithAppController:self];
		[prefsButton setEnabled:false];
		[prefsController showPreferences];
	}
}

- (UIWindow *)appsMainWindow
{
	return window;
}

- (void)anotherApplicationFinishedLaunching:(struct __GSEvent *)event
{
	[self applicationWillSuspend];
}

- (void)refreshTextViewFromDefaults
{
	[self refreshTextViewFromDefaultsToolbarsOnly:NO];
}

- (void)refreshTextViewFromDefaultsToolbarsOnly:(BOOL)toolbarsOnly
{
	float scrollPercentage;
	if (!toolbarsOnly)
	{
		[textView setTextSize:[defaults textSize]];

		textInverted = [defaults inverted];
		[textView invertText:textInverted];

		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGRect visRect = [textView visibleRect];
		scrollPercentage = visRect.origin.y / overallRect.size.height;
		//GSLog(@"scroll percent: %f",scrollPercentage);
		[textView setTextFont:[defaults textFont]];

		[self toggleStatusBarColor];
	}
	if (readingText)
	{  // Let's avoid the weird toggle behavior.
		[navBar hide:NO];
		[bottomNavBar hide:NO];
		[self hideSlider];
	}
	else // not reading text
	{
		[bottomNavBar hide:YES];
	}

	if (![defaults navbar])
		[textView setMarginTop:48];
	else
		[textView setMarginTop:0];
	if (![defaults toolbar])
		[textView setBottomBufferHeight:48];
	else
		[textView setBottomBufferHeight:0];
	if (!toolbarsOnly)
	{
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		//	[textView loadBookWithPath:[textView currentPath]];
		[textView setFrame:rect];
		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGPoint thePoint = CGPointMake(0, (scrollPercentage * overallRect.size.height));
		[textView scrollPointVisibleAtTopLeft:thePoint];
	}
}

- (NSString *)currentBrowserPath
{
	return [[navBar topBrowser] path];
}

- (void)toggleStatusBarColor 	// Thought this might be a nice touch
//TODO: This looks weird with the navbars down.  Perhaps we should change
//the navbars to the black type?  Or have the status bar be black only
//when the top navbar is hidden?  Also I'd prefer to have the status
//bar white when in the browser view, since the browser is white.
{
	int lOrientation = 0;
	if ([defaults isRotate90])
		lOrientation = 90;
	//GSLog(@"toggleStatusBarColor Orientation =%d", lOrientation);
	if ([defaults inverted]) {
		[self setStatusBarMode:3 orientation:lOrientation duration:0.25];
	} else {
		[self setStatusBarMode:0 orientation:lOrientation duration:0.25];
	}
}

- (void) dealloc
{
	[navBar release];
	[bottomNavBar release];
	[mainView release];
	[progressIndicator release];
	[textView release];
	if (nil != imageView)
		[imageView release];
	if (nil != scrollerSlider)
		[scrollerSlider release];
	if (nil != animator)
		[animator release];
	if (nil != alpha)
		[alpha release];
	[defaults release];
	[buttonImg release];
	[minusButton release];
	[plusButton release];
	[invertButton release];
	[rotateButton release];
	[super dealloc];
}

- (void) rotateButtonCallback:(UINavBarButton*) button
{
	if (![button isPressed]) // mouse up events only, kids!
	{
		[defaults setRotate90:![defaults isRotate90]];
		[self rotateApp];
	}	
}

- (void)rotateApp
{
	GSLog(@"rotateApp");
	CGSize lContentSize = [textView contentSize];	
	//GSLog(@"contentSize:w=%f, h=%f", lContentSize.width, lContentSize.height);
	//GSLog(@"rotateApp");
	CGRect rect = [defaults fullScreenApplicationContentRect];
	CGAffineTransform lTransform = CGAffineTransformMakeTranslation(0,0);
	//UIAnimator *anim = [[UIAnimator alloc] init];
	[self toggleStatusBarColor];
	if ([defaults isRotate90])
	{
		int degree = 90;
		CGAffineTransform lTransform2  = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
		//BCC: translate to have the center of rotation (top left corner) in the middle of the view
		lTransform = CGAffineTransformTranslate(lTransform, -1*rect.size.width/2, -1*rect.size.height/2);
		//BCC: perform the actual rotation
		//lTransform = CGAffineTransformRotate(lTransform, M_PI/2);
		lTransform = CGAffineTransformConcat(lTransform2, lTransform);
		//BCC: translate back so the bottom right corner of the view is at the bottom left of the phone
		//lTransform = CGAffineTransformTranslate(lTransform, lCurrentRect.size.height - lCurrentRect.size.width/2, lCurrentRect.size.height/2 - lCurrentRect.size.width);
		//BCC: translate back so the top left corner of the view is at the top right of the phone
		lTransform = CGAffineTransformTranslate(lTransform, rect.size.width/2, -rect.size.height/2);
	} else
	{
	}
	struct CGAffineTransform lMatrixprev = [window transform];
	//GSLog(@"prev matrix: a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f", lMatrixprev.a, lMatrixprev.b, lMatrixprev.c, lMatrixprev.d, lMatrixprev.tx, lMatrixprev.ty);
	//GSLog(@"new matrix: a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f", lTransform.a, lTransform.b, lTransform.c, lTransform.d, lTransform.tx, lTransform.ty);
	//GSLog(@"rect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	if (! CGAffineTransformEqualToTransform(lTransform,lMatrixprev))
	{
		//remember the previous position
		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGRect visRect = [textView visibleRect];
		float scrollPercentage = visRect.origin.y / overallRect.size.height;
		if ([defaults isRotate90])
		{
			[window setFrame: rect];
			[window setBounds: rect];
			[mainView setFrame: rect];
			[mainView setBounds: rect];
		}






		[transitionView setFrame: rect];
		[textView setFrame: rect];
		[self refreshTextViewFromDefaults];
		[textView setHeartbeatDelegate:self];
		int            subchapter = [textView getSubchapter];
		NSString      *recentFile   = [textView currentPath];


		overallRect = [[textView _webView] frame];
//		GSLog(@"new overall height: %f", overallRect.size.height);
		float scrollPoint = (float) scrollPercentage * overallRect.size.height;

		[textView loadBookWithPath:recentFile subchapter:subchapter];
		textViewNeedsFullText = NO;
		[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
									 animated:NO];

		[window setTransform: lTransform];

		if (![defaults isRotate90])
		{
			rect.origin.y+=20; //to take into account the status bar
			[window setFrame: rect];
		}
		[self updateToolbar: 0];
		[self updateNavbar];

		//[navBar showTopNavBar:NO];
		//[navBar show];
		[bottomNavBar hide:NO];
	//	GSLog(@"showing the slider");
		[self hideSlider];
	}
//	

	//BCC: animate this
	/*	
		UITransformAnimation *scaleAnim = [[UITransformAnimation alloc] initWithTarget: window];
		struct CGAffineTransform lMatrixprev = [window transform];
		[scaleAnim setStartTransform: lMatrixprev];
		[scaleAnim setEndTransform: lTransform];
		[anim addAnimation:scaleAnim withDuration:5.0f start:YES]; 
		[anim autorelease];	//should we do this, it continues to leave for the duration of the animation
		*/
}
- (void) preferenceAnimationDidFinish
{
	[prefsButton setEnabled:true];
}
@end
