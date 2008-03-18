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
#include <stdio.h>
#import "FileNavigationItem.h"

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
/**
 * Log all notifications.
 */
- (void)debugNotification:(NSNotification*)p_note {
  GSLog(@"NOTIFICATION: %@", [p_note name]);
}

- (void) applicationDidFinishLaunching: (id) unused
{
  // Only log if the log file already exists!
  if([[NSFileManager defaultManager] fileExistsAtPath:OUT_FILE]) {    
    freopen([OUT_FILE fileSystemRepresentation], "a", stderr);
    freopen([OUT_FILE fileSystemRepresentation], "a", stdout);
    GSLog(@"Should be logging to file now...");
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(debugNotification:) name:nil object:nil];
  }
	
	//investigate using [self setUIOrientation 3] that may alleviate for the need of a weirdly sized window
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	//bcc rect to change for rotate90

	doneLaunching = NO;

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateToolbar:)
												 name:@"toolbarDefaultsChanged"
											   object:nil];

	window = [[UIWindow alloc] initWithContentRect:[UIHardware fullScreenApplicationContentRect]];  
  mainView = [[UIView alloc] initWithFrame:[window bounds]];
  [window setContentView:mainView];
  
  transitionView = [[UITransitionView alloc] initWithFrame:[window bounds]];
  [mainView addSubview:transitionView];
	[transitionView setDelegate:self];
    
  NSString *coverart = [EBookImageView coverArtForBookPath:[defaults lastBrowserPath]];
  if(coverart != nil) {
    UIImageView *tmpEBIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];                            
    [tmpEBIV setFrame:[window bounds]];
    [mainView addSubview:tmpEBIV];
    
    imageView = [[EBookImageView alloc] initWithContentsOfFile:coverart withFrame:[window bounds] scaleAspect:YES];
    [transitionView transition:6 fromView:tmpEBIV toView:imageView];
    
    [tmpEBIV removeFromSuperview];
    [tmpEBIV release];
  } else {
    imageView = [[EBookImageView alloc] 
                 initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"]
                 withFrame:[window bounds]
                 scaleAspect:NO];
    [mainView addSubview:imageView];  
  }  

	/*
  struct CGSize progsize = [UIProgressIndicator defaultSizeForStyle:0];
  progressIndicator = [[UIProgressIndicator alloc] 
		initWithFrame:CGRectMake((rect.size.width-progsize.width)/2,
				(rect.size.height-progsize.height)/2,
				progsize.width, 
				progsize.height)];
	[progressIndicator setStyle:0];
   */
  
	readingText = [defaults readingText];
    
  // Heart beat will trigger doc loading and the rest of the init process.
  // We want to get back out to the main runloop to let some of the image & view stuff happen.
  textView = [[EBookView alloc] initWithFrame:[window bounds]];
  [textView setHeartbeatDelegate:self];


  [window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];

//	[mainView addSubview:progressIndicator];
//	[progressIndicator startAnimation];
  GSLog(@"applicationDidFinishLaunching: finished");
}

/**
 * Heartbeat isn't needed in main app at this point, but we need to init
 * a delegate or the navbar toggle won't work.
 */
- (void)heartbeatCallback:(id)ignored {
  if(!doneLaunching) {
    doneLaunching = YES;
    [self finishUpLaunch];
  }
}


/**
 * Store screen shot (if enabled), setup navigation bar, and start displaying the 
 * last read file.  Takes down splash image if it was present.
 */
- (void)finishUpLaunch {
  GSLog(@"finishUpLaunch");
	NSString *recentFile = [defaults fileBeingRead];
  
  [self setupNavbar];
	[self setupToolbar];

  // Create navigation bar
	FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithTitle:@"Books" forPath:[BooksDefaultsController defaultEBookPath]];
	[navBar pushNavigationItem:tempItem];
  
  // Get last browser path and start loading files
	NSString *lastBrowserPath;
  if(readingText) {
    lastBrowserPath = [recentFile stringByDeletingLastPathComponent];
  } else {
    lastBrowserPath = [defaults lastBrowserPath];
  }
  
	NSMutableArray *arPathComponents = [[NSMutableArray alloc] init]; 
  
  GSLog(@"Original lastBrowserPath: %@", lastBrowserPath);
  
	if(![lastBrowserPath isEqualToString:[BooksDefaultsController defaultEBookPath]]) {
    
		[arPathComponents addObject:lastBrowserPath];
    lastBrowserPath = [lastBrowserPath stringByDeletingLastPathComponent]; // prime for loop
    
    // FIXME: Taking the bottom path from the pref's file probably causes problems when upgrading.
    while((![lastBrowserPath isEqualToString:[BooksDefaultsController defaultEBookPath]]) 
          && (![lastBrowserPath isEqualToString:@"/"])) {
			[arPathComponents addObject:lastBrowserPath];
      lastBrowserPath = [lastBrowserPath stringByDeletingLastPathComponent];
		} // while
	} // if
  
  GSLog(@"Modified lastBrowserPath %@", lastBrowserPath);
  
	NSEnumerator *pathEnum = [arPathComponents reverseObjectEnumerator];
	NSString *curPath;  
	while(nil != (curPath = [pathEnum nextObject])) {
    GSLog(@"Pushing path component %@", [curPath lastPathComponent]);
		FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithPath:curPath];
		[navBar pushNavigationItem:tempItem];
		[tempItem release];
	}
  
  // Hack the image view into place so we get a nice cover->document transition
  [navBar setTopDocumentView:imageView];
  
	if(readingText) {
		if([[NSFileManager defaultManager] fileExistsAtPath:recentFile]) {
      // Pushing the file onto the toolbar will trigger it being opened.
      FileNavigationItem *fni = [[FileNavigationItem alloc] initWithDocument:recentFile];
      [navBar pushNavigationItem:fni];
      [fni release];
		} else {  // Recent file has been deleted!  RESET!
      GSLog(@"File %@ doesn't exist anymore.", recentFile);
			readingText = NO;
			[defaults setReadingText:NO];
			[defaults setFileBeingRead:@""];
			[defaults setLastBrowserPath:[BooksDefaultsController defaultEBookPath]];
			[defaults removePerFileDataForFile:recentFile];
		}    
	} else {
    GSLog(@"Not reading text.");
  }

  GSLog(@"After filebrowser");
  

  
  [self refreshTextViewFromDefaultsToolbarsOnly:NO];

  if(!readingText) {
    // Either we didn't have a file open, or it doesn't exist anymore.
    // We need to transition to the file browser view.
    GSLog(@"Transitioning to file browser.");
    //[transitionView transition:6 fromView:imageView toView:[navBar topBrowser]];
    [navBar show];
  }
  
  // FIXME: We shouldn't clear this if we are in fact trying to show an image.
  [imageView removeFromSuperview];
  [mainView addSubview:textView];
//  [imageView autorelease];
 // imageView = nil;
  
  [mainView addSubview:navBar];
	[mainView addSubview:bottomNavBar];
  
  [navBar hide:YES];
  [bottomNavBar hide:YES];
  [self hideSlider];  
  
	//bcc rotation
	[self rotateApp];

	[arPathComponents release];

	[navBar enableAnimation];
	//[progressIndicator stopAnimation];
	//[progressIndicator removeFromSuperview];
  
  GSLog(@"finishUpLaunch done.");
}


/**
 * Heartbeat is needed in main app at this point.
 * It is used as a delegate for the navbar (without it hte toggle won't work) a delegate or the navbar toggle won't work.
 * It is also used to complete the load of documents which were already partially loaded when opened from the file browser
 */
	- (void)heartbeatCallback:(id)ignored {
		if ((textViewNeedsFullText) && ![transitionView isTransitioning])
		{
			[textView loadBookWithPath:[textView currentPath] subchapter:[defaults lastSubchapterForFile:[textView currentPath]]];
			textViewNeedsFullText = NO;
		}

	}
=======
>>>>>>> File browser finally works again, but re-launch to open existing file leaves blank view:source/BooksApp.m

/**
 * Hide the navigation bars.
 */
- (void)hideNavbars {
  GSLog(@"BooksApp-hideNavbars");
	struct CGRect rect = [window bounds];
	[textView setFrame:rect];
	[navBar hide:NO];
	[bottomNavBar hide:NO];
	[self hideSlider];
}

/**
 * Toggle visibility of the navigation bars.
 */
- (void)toggleNavbars {
  GSLog(@"BooksApp-toggleNavbars");
	[navBar toggle];
	[bottomNavBar toggle];
  
	if (nil == scrollerSlider) {
		[self showSlider:true];
	} else {
		[self hideSlider];
	}
}

/**
 * Show the scroll slider.
 *
 * FIXME: Is it really necessary to destory and reinit this thing every time??
 */
- (void)showSlider:(BOOL)withAnimation {
  GSLog(@"BooksApp-showSlider");
	CGRect rect = CGRectMake(0, 48, [defaults fullScreenApplicationContentRect].size.width, 48);
	CGRect lDefRect = [defaults fullScreenApplicationContentRect];
	if (nil != scrollerSlider) {
		[scrollerSlider removeFromSuperview];
		[scrollerSlider autorelease];
		scrollerSlider = nil;
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
	if (withAnimation) {
		if (animator != nil) {
			[animator release];
    }
		animator = [[UIAnimator alloc] init];
		if (alpha != nil) {
			[alpha release];
    }
		alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
		[alpha setStartAlpha:0];
		[alpha setEndAlpha:1];
		[animator addAnimation:alpha withDuration:0.25 start:YES];
	} else {
		[scrollerSlider setAlpha:1];
	}
}

- (void)hideSlider {
  GSLog(@"BooksApp-hideSlider");
	if (scrollerSlider != nil) {
		if (animator != nil) {
			[animator release];
    }
    
		animator = [[UIAnimator alloc] init];
		if (alpha != nil) {
			[alpha release];
    }
    
		alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
		[alpha setStartAlpha:1];
		[alpha setEndAlpha:0];
		[animator addAnimation:alpha withDuration:0.1 start:YES];
		[scrollerSlider release];
		scrollerSlider = nil;
	}
}

- (void)handleSlider:(id)sender {
	if (scrollerSlider != nil) {
		CGPoint scrollness = CGPointMake(0, [scrollerSlider value]);
		[textView scrollPointVisibleAtTopLeft:scrollness animated:NO];
	}
}

/**
 * Show the document and return the view used to allow for transition.
 */
- (UIView*)showDocumentAtPath:(NSString*)p_path {
  NSString *ext = [p_path pathExtension];
  BOOL isPicture = ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"]);
  UIView *ret = nil;
  
  // Always kill the image view.  We'll reuse the textView for now.
  [imageView autorelease];

  // Make sure the "file read" dot is updated.
  [[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE object:p_path];

  if (isPicture) {
    GSLog(@"Loading picture: %@", p_path);
    
    imageView = [[EBookImageView alloc] initWithContentsOfFile:p_path];
    ret = imageView;
  } else { 
    //text or HTML file
    readingText = YES;
    BOOL sameFile = [[textView currentPath] isEqualToString:p_path];
    GSLog(@"Loading book %@ (previous was: %@)", p_path, [textView currentPath]);
    if (!sameFile) {
      GSLog(@"Really loading...");
      // Slight optimization.  If the file is already loaded,
      // don't bother reloading.
      int subchapter = [defaults lastSubchapterForFile:p_path];
      float scrollPoint = (float) [defaults lastScrollPointForFile:p_path
                                                      inSubchapter:subchapter];
      
      [textView loadBookWithPath:p_path subchapter:subchapter];
      [textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint) animated:NO];
    }
    // Whether we loaded it or not, need to return the text view.
    ret = textView;
  }  
  
  if (isPicture) {
    [navBar show];
    [bottomNavBar hide:YES];
  } else {
    [navBar hide:NO];
    if (![defaults toolbar]) {
      [bottomNavBar show];
    } else {
      [bottomNavBar hide:NO];
    }
  }

  return ret;
}

/**
 * Cleanup the current document.  Saves settings for books or dealloc's views for images.
 */
- (void)closeCurrentDocument {
  GSLog(@"Closing document.");
  if(readingText) {
    struct CGRect  selectionRect = [textView visibleRect];
    int            subchapter    = [textView getSubchapter];
    NSString      *filename      = [textView currentPath];
    
    [defaults setLastScrollPoint: (unsigned int) selectionRect.origin.y
                   forSubchapter:subchapter
                         forFile:filename];
    [defaults setLastSubchapter:subchapter forFile:filename];
  } else {
    [imageView release];
    imageView = nil;
  }
  
  readingText = NO;
  [bottomNavBar hide:YES];
  [self hideSlider];
}

/**
 * Called by the file browser objects when a user taps a file or folder.  Calls to navBar
 * to push whatever was tapped.  Navbar will call us back to actually open something.
 */
- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file {
	BOOL isDir = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  if(![fileManager fileExistsAtPath:file isDirectory:&isDir]) {
    GSLog(@"Tried to open non-existant path at %@", file);
    return;
  }
  
  FileNavigationItem *tempItem;
	if (isDir) {
    GSLog(@"Loading browser for directory %@", file);
		tempItem = [[FileNavigationItem alloc] initWithPath:file];
   	[defaults setLastBrowserPath:file];
	} else {
    // not a directory
    GSLog(@"Loading file: %@", file);
		tempItem = [[FileNavigationItem alloc] initWithDocument:file];
		// [defaults removePerFileDataForFile:file]; // Why would we remove per-file settings when we're opening the file???
  }
  
  [navBar pushNavigationItem:tempItem];
  [tempItem release];
}


- (void)cleanUpBeforeQuit {
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
	[defaults synchronize];
  GSLog(@"Books is terminating.");
  GSLog(@"========================================================");
}

- (void) applicationWillSuspend {
	[self cleanUpBeforeQuit];
}

- (void)applicationWillTerminate {
  // Should always suspend before we terminate, so no need to cleanup twice.
	//[self cleanUpBeforeQuit];
}

// FIXME: Seems like this text stuff should be purely in the EBookView class.
- (void)embiggenText:(UINavBarButton *)button {
	if (![button isPressed]) {// mouse up events only, kids!
		CGRect rect = [[textView _webView] frame];
		[textView embiggenText];
		if (scrollerSlider != nil) {
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

- (void)ensmallenText:(UINavBarButton *)button {
	if (![button isPressed]) {// mouse up events only, kids!
		CGRect rect = [[textView _webView] frame];
		[textView ensmallenText];
		if (scrollerSlider != nil) {
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

- (void)invertText:(UINavBarButton *)button {
  if (![button isPressed]) { // mouse up events only, kids!
		textInverted = !textInverted;
		[textView invertText:textInverted];
		[defaults setInverted:textInverted];
		[self toggleStatusBarColor];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		[textView setFrame:rect];
	}	
}

- (void)pageDown:(UINavBarButton *)button {
	if (![button isPressed]) {
		[textView pageDownWithTopBar:![defaults navbar]
						   bottomBar:![defaults toolbar]];
	}	
}

- (void)pageUp:(UINavBarButton *)button {
	if (![button isPressed]) {
		[textView pageUpWithTopBar:![defaults navbar]
						 bottomBar:![defaults toolbar]];
	}	
}

- (void)chapForward:(UINavBarButton *)button 
{
	GSLog(@"chapForward start");
	if (![button isPressed]) {
		if ([textView gotoNextSubchapter] == YES) {
			[self hideSlider];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		} else {
			NSString *nextFile = [[navBar topBrowser] fileAfterFileNamed:[textView currentPath]];
			if ((nil != nextFile) && [nextFile isReadableTextFilePath]) {
				[self hideSlider];

				struct CGRect visRect = [textView visibleRect];
				int            subchapter = [textView getSubchapter];
				NSString      *filename   = [textView currentPath];

				[defaults setLastScrollPoint:(unsigned int)visRect.origin.y
							   forSubchapter:subchapter
									 forFile:filename];
				[defaults setLastSubchapter:subchapter forFile:filename];

				[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
																	object:[textView currentPath]];

				FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithDocument:nextFile];
				[navBar pushNavigationItem:tempItem];
				[self refreshTextViewFromDefaultsToolbarsOnly:NO];

				subchapter = [defaults lastSubchapterForFile:nextFile];
				int lastPt = [defaults lastScrollPointForFile:nextFile inSubchapter:subchapter]; BOOL didLoadAll = NO; 

				[textView loadBookWithPath:nextFile subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, (float) lastPt) animated:NO];

				[tempItem release];
			}
		}
	}	

	GSLog(@"chapForward end");
}

- (void)chapBack:(UINavBarButton *)button {
	if (![button isPressed]) {
		if ([textView gotoPreviousSubchapter] == YES) {
			[self hideSlider];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		} else {
			NSString *prevFile = [[navBar topBrowser] fileBeforeFileNamed:[textView currentPath]];
			if ((nil != prevFile) && [prevFile isReadableTextFilePath]) {
				[self hideSlider];

				struct CGRect visRect = [textView visibleRect];
				int            subchapter = [textView getSubchapter];
				NSString      *filename   = [textView currentPath];

				[defaults setLastScrollPoint: (unsigned int) visRect.origin.y
							   forSubchapter: subchapter
									 forFile: filename];
				[defaults setLastSubchapter:subchapter forFile:filename];

				[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
																	object:[textView currentPath]];

				FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithDocument:prevFile];
				[navBar pushNavigationItem:tempItem];
				[self refreshTextViewFromDefaultsToolbarsOnly:NO];

				subchapter = [defaults lastSubchapterForFile:prevFile];
				int lastPt = [defaults lastScrollPointForFile:prevFile
												 inSubchapter:subchapter];
				BOOL didLoadAll = NO; 

				CGRect rect = [defaults fullScreenApplicationContentRect];
				int numScreens = (lastPt / rect.size.height) + 1;  // how many screens down are we?  
				int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));  //bcc I wonder what is 265000 but it has to be replaced
				[textView loadBookWithPath:prevFile numCharacters:numChars
								didLoadAll:&didLoadAll subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, (float) lastPt)
											 animated:NO];
				[tempItem release];
			}
		}
	}	
}

// CHANGED: Moved navbar and toolbar setup here from applicationDidFinishLaunching

/**
 * Create the nav bar (file browser).
 */
- (void)setupNavbar {
  GSLog(@"BooksApp-setupNavbar");
	struct CGRect rect = [mainView bounds];
	[navBar release]; //BCC in case this is not the first time this method is called
	navBar = [[HideableNavBar alloc] initWithFrame:
            CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f) delegate:self transitionView:transitionView];

	[navBar setExtensions:[NSArray arrayWithObjects:@"txt", @"htm", @"html", @"pdb", @"jpg", @"png", @"gif", nil]];
	[navBar hideButtons];

  float lMargin = 45.0f;
	[navBar setRightMargin:lMargin];
	//position the prefsButton in the margin
	//for some reason cannot click on the button when it is there
	prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(rect.size.width-lMargin,9,40,30) selector:@selector(showPrefs:) flipped:NO];
	//prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(275,9,40,30) selector:@selector(showPrefs:) flipped:NO];

	[navBar addSubview:prefsButton];
}

/**
 * Create the tool bar (reader).
 */
- (void)setupToolbar {
  GSLog(@"BooksApp-setupToolbar");
	struct CGRect rect = [mainView bounds];
	[bottomNavBar release]; //BCC in case this is not the first time this method is called
	bottomNavBar = [[HideableNavBar alloc] initWithFrame:
		CGRectMake(rect.origin.x, rect.size.height - 48.0f, 
				rect.size.width, 48.0f) delegate:self transitionView:transitionView];

	[bottomNavBar setBarStyle:0];

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

/**
 * Return a pre-configured toolbar button with _up and _down images setup.
 */
- (UINavBarButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped {
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

/**
 * Get an image from the bundle.
 */
- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped {
	NSBundle *bundle = [NSBundle mainBundle];
	imgPath = [bundle pathForResource:name ofType:@"png"];
	UIImage *buttonImg = [[UIImage alloc]initWithContentsOfFile:imgPath];
	if (flipped) [buttonImg setOrientation:4];
	return [buttonImg autorelease];
}

- (void)updateNavbar {
	CGRect rect = [defaults fullScreenApplicationContentRect];
	[navBar setFrame: 	CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];
	float lMargin = 45.0f;
	[prefsButton setFrame:CGRectMake(rect.size.width-lMargin,9,40,30) ];
}

- (void)updateToolbar:(NSNotification *)notification {
	GSLog(@"%s Got toolbar update notification.", _cmd);
	BOOL lBottomBarHidden = [bottomNavBar hidden];
	[bottomNavBar removeFromSuperview];
	[self setupToolbar];
	[mainView addSubview:bottomNavBar];
	if (lBottomBarHidden) {
    [bottomNavBar hide:NO];
  }
}

- (void)setTextInverted:(BOOL)b {
	textInverted = b;
}

- (void)showPrefs:(UINavBarButton *)button {
	if (![button isPressed]) // mouseUp only
	{
		GSLog(@"Showing Preferences View");
		PreferencesController *prefsController = [[PreferencesController alloc] initWithAppController:self];
		[prefsButton setEnabled:false];
		[prefsController showPreferences];
	}
}

- (UIWindow *)appsMainWindow {
	return window;
}

- (void)anotherApplicationFinishedLaunching:(struct __GSEvent *)event {
	[self applicationWillSuspend];
}

- (void)refreshTextViewFromDefaultsToolbarsOnly:(BOOL)toolbarsOnly {
	float scrollPercentage;
	if (!toolbarsOnly) {
		[textView setTextSize:[defaults textSize]];

		textInverted = [defaults inverted];
		[textView invertText:textInverted];

		struct CGRect overallRect = [[textView _webView] frame];
		struct CGRect visRect = [textView visibleRect];
		scrollPercentage = visRect.origin.y / overallRect.size.height;
		[textView setTextFont:[defaults textFont]];

		[self toggleStatusBarColor];
	}
  
	if (readingText) {
    // Let's avoid the weird toggle behavior.
		[navBar hide:NO];
		[bottomNavBar hide:NO];
		[self hideSlider];
	} else {
    // not reading text
		[bottomNavBar hide:YES];
	}

	if (![defaults navbar]) {
		[textView setMarginTop:48];
  } else {
		[textView setMarginTop:0];
  }
  
	if (![defaults toolbar]) {
		[textView setBottomBufferHeight:48];
	} else {
		[textView setBottomBufferHeight:0];
  }
  
	if (!toolbarsOnly) {
		struct CGRect rect = [window bounds];
		[textView setFrame:rect];
		struct CGRect overallRect = [[textView _webView] frame];
		struct CGPoint thePoint = CGPointMake(0, (scrollPercentage * overallRect.size.height));
		[textView scrollPointVisibleAtTopLeft:thePoint];
	}
}

- (NSString *)currentBrowserPath {
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

- (void) dealloc {
	[navBar release];
	[bottomNavBar release];
	[mainView release];
	//	[progressIndicator release];
	[textView release];
	[imageView release];
	[scrollerSlider release];
  [animator release];
	[alpha release];
	[defaults release];
	[minusButton release];
	[plusButton release];
	[invertButton release];
	[rotateButton release];
	[super dealloc];
}

- (void) rotateButtonCallback:(UINavBarButton*) button {
	if (![button isPressed]) // mouse up events only, kids!
	{
		[defaults setRotate90:![defaults isRotate90]];
		[self rotateApp];
	}	
}

/**
 * Toggle rotation status.
 */
- (void)rotateApp {
	CGSize lContentSize = [textView contentSize];	
	//GSLog(@"contentSize:w=%f, h=%f", lContentSize.width, lContentSize.height);
	//GSLog(@"rotateApp");
	CGRect rect = [defaults fullScreenApplicationContentRect];
	CGAffineTransform lTransform = CGAffineTransformMakeTranslation(0,0);
	[self toggleStatusBarColor];
	if ([defaults isRotate90]) {
		int degree = 90;
		CGAffineTransform lTransform2  = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
		//BCC: translate to have the center of rotation (top left corner) in the middle of the view
		lTransform = CGAffineTransformTranslate(lTransform, -1*rect.size.width/2, -1*rect.size.height/2);
		//BCC: perform the actual rotation
		lTransform = CGAffineTransformConcat(lTransform2, lTransform);
		//BCC: translate back so the bottom right corner of the view is at the bottom left of the phone
		//BCC: translate back so the top left corner of the view is at the top right of the phone
		lTransform = CGAffineTransformTranslate(lTransform, rect.size.width/2, -rect.size.height/2);
	} 

	struct CGAffineTransform lMatrixprev = [window transform];

	if(!CGAffineTransformEqualToTransform(lTransform,lMatrixprev)) {
		//remember the previous position
		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGRect visRect = [textView visibleRect];
		float scrollPercentage = visRect.origin.y / overallRect.size.height;
		if ([defaults isRotate90]) {
			[window setFrame: rect];
			[window setBounds: rect];
			[mainView setFrame: rect];
			[mainView setBounds: rect];
		}

		[transitionView setFrame: rect];
		[textView setFrame: rect];
		[self refreshTextViewFromDefaultsToolbarsOnly:NO];
		[textView setHeartbeatDelegate:self];
		int            subchapter = [textView getSubchapter];
		NSString      *recentFile   = [textView currentPath];


		overallRect = [[textView _webView] frame];
		//		GSLog(@"new overall height: %f", overallRect.size.height);
		float scrollPoint = (float) scrollPercentage * overallRect.size.height;

		[textView loadBookWithPath:recentFile subchapter:subchapter];
		//BCC something like the line bellow should work but I can't find what
		//	[textView reflowBook];
		[UIView beginAnimations: @"rotate"];
		//[UIView setAnimationDuration:10.0];
		textViewNeedsFullText = NO;
		[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
									 animated:NO];
		[window setTransform: lTransform];

		if (![defaults isRotate90])
		{
			rect.origin.y+=20; //to take into account the status bar
			[window setFrame: rect];
		}
		[UIView endAnimations];
		[self updateToolbar: 0];
		[self updateNavbar];

		[bottomNavBar hide:NO];
		//	GSLog(@"showing the slider");
		[self hideSlider];
	}
	//	
}

/**
 * Ensure that the preferences screen can't be shown multiple times while the animation is in progress.
 */
- (void) preferenceAnimationDidFinish {
	[prefsButton setEnabled:true];
}
@end
