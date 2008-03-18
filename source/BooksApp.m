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

- (void)applicationDidFinishLaunching:(id)unused {
  // Only log if the log file already exists!
  if([[NSFileManager defaultManager] fileExistsAtPath:OUT_FILE]) {    
    freopen([OUT_FILE fileSystemRepresentation], "a", stderr);
    freopen([OUT_FILE fileSystemRepresentation], "a", stdout);
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(debugNotification:) name:nil object:nil];
  }
  
  m_documentExtensions = [[NSArray arrayWithObjects:@"txt", @"htm", @"html", @"pdb", @"jpg", @"png", @"gif", nil] retain];
	
	//investigate using [self setUIOrientation 3] that may alleviate for the need of a weirdly sized window
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	//bcc rect to change for rotate90

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
  
  /*
   * We need to fix up any prefs-weirdness relating to file path before we try to open a document.
   * Figure out if we have a directory or a file and if it exists.  If it doesn't, jump back to the
   * default root and let them start over.
   */
  NSString *recentFile = [defaults lastBrowserPath];
  BOOL isDir = NO;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:recentFile isDirectory:&isDir];
  
  readingText = exists && !isDir;
  
  if(!exists) {
    [defaults setLastBrowserPath:[BooksDefaultsController defaultEBookPath]];
    [defaults removePerFileDataForFile:recentFile];
    recentFile = [defaults lastBrowserPath];
  }
  
  /*
   * If the current path has cover art, transition to it.  If not, we have to redisplay
   * the startup image, but this time in the real image view.  We'll move to it without
   * transition.  It sucks to load the Default image twice (thrice if you count Springboard
   * showing it), but we need to have it loaded into a DIFFERENT imageview in order for the
   * transitions to work.  We can't show a transition by just setting the image path on
   * a single imageview.
   */
  NSString *coverart = [EBookImageView coverArtForBookPath:recentFile];
  if(coverart != nil) {
    m_startupImage = [[EBookImageView alloc] initWithContentsOfFile:coverart 
                                                     withFrame:[window bounds] 
                                                   scaleAspect:YES];
    [transitionView transition:1 toView:m_startupImage];
  } else {
    m_startupImage = [[EBookImageView alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"]
                                                     withFrame:[window bounds] 
                                                   scaleAspect:NO];
    [transitionView transition:0 toView:m_startupImage];
  }
  // At this point, we're showing either the startup book or the cover image in the real imageView and m_startupView is gone.

	/*
  struct CGSize progsize = [UIProgressIndicator defaultSizeForStyle:0];
  progressIndicator = [[UIProgressIndicator alloc] 
		initWithFrame:CGRectMake((rect.size.width-progsize.width)/2,
				(rect.size.height-progsize.height)/2,
				progsize.width, 
				progsize.height)];
	[progressIndicator setStyle:0];
   */

  [self toggleStatusBarColor];
  
  [window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];

//	[mainView addSubview:progressIndicator];
//	[progressIndicator startAnimation];
  
  // We need to get back to the main runloop for some things to finish up.  Schedule a timer to
  // fire almost immediately.
  [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(finishUpLaunch) userInfo:nil repeats:NO];
}

/**
 * This needs to be called once at startup.
 * Should be called at the point where the next toolbar or view change needs
 * to trigger animation.  If readingText, call right before swtiching to the text view.
 * If not reading text and at root, call before pushing the root entry.  If not reading
 * text and NOT at the root, call right before the last path push.
 *
 * Clear as mud, right?
 */
- (void)transitionNavbarAnimation {
  [mainView addSubview:navBar];
  [mainView addSubview:bottomNavBar];

  [navBar enableAnimation];
}

/**
 * Store screen shot (if enabled), setup navigation bar, and start displaying the 
 * last read file.  Takes down splash image if it was present.
 */
- (void)finishUpLaunch {
  NSString *recentFile = [defaults lastBrowserPath];

  [self setupNavbar];
	[self setupToolbar];

  // Get last browser path and start loading files
	NSString *lastBrowserPath;
  if(readingText) {
    lastBrowserPath = [recentFile stringByDeletingLastPathComponent];
  } else {
    lastBrowserPath = [defaults lastBrowserPath];
  }
  
	NSMutableArray *arPathComponents = [[NSMutableArray alloc] init]; 
  
	if(![lastBrowserPath isEqualToString:[BooksDefaultsController defaultEBookPath]]) {
    
		[arPathComponents addObject:lastBrowserPath];
    lastBrowserPath = [lastBrowserPath stringByDeletingLastPathComponent]; // prime for loop
    
    // FIXME: Taking the bottom path from the pref's file probably causes problems when upgrading.
    NSString *stopAtPath = [[BooksDefaultsController defaultEBookPath] stringByDeletingLastPathComponent];
    while(![lastBrowserPath isEqualToString:stopAtPath] && ![lastBrowserPath isEqualToString:@"/"]) {
			[arPathComponents addObject:lastBrowserPath];
      lastBrowserPath = [lastBrowserPath stringByDeletingLastPathComponent];
		} // while
	} // if
  
  // Loop over all the paths and add them to the nav bar.
  int pathCount = [arPathComponents count];
  for(pathCount = pathCount-1; pathCount >= 0 ; pathCount--) {    
    if(!readingText && pathCount == 0) {
      /*
       * We're not reading a book and we're on the last item.  We want animation on so the 
       * book image gets transitioned off.
       */
      [self transitionNavbarAnimation];
    }
    
    NSString *curPath = [arPathComponents objectAtIndex:pathCount];
    // Add the current path to the toolbar
    [self fileBrowser:nil fileSelected:curPath];
    
    // Need to show the navbar after the last transition if we're not reading.
    if(!readingText && pathCount == 0) {
      [navBar show];
    }
  }
      
	if(readingText) {
    /*
     * If we are reading text, then we DIDN'T finish setting up the navbar during
     * the path-push process.  So we'd better do it now!
     */
    [self transitionNavbarAnimation];
    
    // Pushing the file onto the toolbar will trigger it being opened.
    UIView *view = [self showDocumentAtPath:recentFile];    
    FileNavigationItem *fni = [[FileNavigationItem alloc] initWithDocument:recentFile view:view];
    [navBar pushNavigationItem:fni];
    [fni release];
    
    // If reading, hide the nav bars (but they need to be added to the view first)
    [navBar hide];
    [bottomNavBar hide];
  }
  
	//bcc rotation
	[self rotateApp];

	[arPathComponents release];

	//[progressIndicator stopAnimation];
	//[progressIndicator removeFromSuperview];
}

- (void)setNavForItem:(FileNavigationItem*)p_item {
  if([p_item isDocument]) {
    // Set nav bars for a document
  } else {
    // Set nav bars for a file browser
    [bottomNavBar hide];
  }
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
	//struct CGRect rect = [window bounds];
	//[textView setFrame:rect];
	[navBar hide];
	[bottomNavBar hide];
}

/**
 * Show the navigation bars.
 */
- (void)showNavbars {
	//struct CGRect rect = [window bounds];
	//[textView setFrame:rect];
	[navBar show];
	[bottomNavBar show];
}

/**
 * Toggle visibility of the navigation bars.
 */
- (void)toggleNavbars {
	[navBar toggle];
	[bottomNavBar toggle];
}

/**
 * Return YES if the image at the given path is an image.
 */
- (BOOL)isDocumentImage:(NSString*)p_path {
  NSString *ext = [p_path pathExtension];
  return ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"]);
}

/**
 * Show the document and return the view used to allow for transition.
 */
- (UIView*)showDocumentAtPath:(NSString*)p_path {
  BOOL isPicture = [self isDocumentImage:p_path];
  UIView *ret = nil;
  
  [defaults setLastBrowserPath:p_path];

  if (isPicture) {
    ret = [[[EBookImageView alloc] initWithContentsOfFile:p_path withFrame:[mainView bounds] scaleAspect:YES] autorelease];
  } else { 
    //text or HTML file
    readingText = YES;
    // Slight optimization.  If the file is already loaded,
    // don't bother reloading.
    int subchapter = [defaults lastSubchapterForFile:p_path];
    float scrollPoint = (float) [defaults lastScrollPointForFile:p_path
                                                    inSubchapter:subchapter];
   
    EBookView *ebv = [[[EBookView alloc] initWithFrame:[mainView bounds] delegate:self parentView:mainView] autorelease];
    [ebv setDelegate:self];
    [ebv loadBookWithPath:p_path subchapter:subchapter];
    
    ret = ebv;
  }  
  
  if (isPicture) {
    [navBar show];
    [bottomNavBar hide];
  } else {
    [navBar hide];
    if (![defaults toolbar]) {
      [bottomNavBar show];
    } else {
      [bottomNavBar hide];
    }
  }
  
  // Make sure the "file read" dot is updated.
  [[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE object:p_path];

  return ret;
}

/**
 * Cleanup the current document.  Saves settings for books or dealloc's views for images.
 */
/*
- (void)closeCurrentDocument {
  GSLog(@"Closing document.");
  if(readingText) {
    [self saveBookPosition];
  } else {
    [imageView release];
    imageView = nil;
  }
  
  readingText = NO;
  [bottomNavBar hide];
}
 */

/**
 * Called by the file browser objects when a user taps a file or folder.  Calls to navBar
 * to push whatever was tapped.  Navbar will call us back to actually open something.
 */
- (void)fileBrowser:(FileBrowser *)browser fileSelected:(NSString *)file {
	BOOL isDir = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  if(![fileManager fileExistsAtPath:file isDirectory:&isDir]) {
    GSLog(@"Tried to open non-existant path at %@", file);
    return;
  }
  
 	[defaults setLastBrowserPath:file];
  
  FileNavigationItem *tempItem;
	if (isDir) {
    FileBrowser *browser = [[FileBrowser alloc] initWithFrame:[mainView bounds]];
    [browser setPath:file];
    [browser setDelegate:self];
    [browser setExtensions:m_documentExtensions];
		tempItem = [[FileNavigationItem alloc] initWithPath:file browser:browser];
    [browser release];
	} else {
    // not a directory
    UIView *displayView = [self showDocumentAtPath:file];
		tempItem = [[FileNavigationItem alloc] initWithDocument:file view:displayView];
  }
  
  [navBar pushNavigationItem:tempItem];
  [tempItem release];
}


- (void)cleanUpBeforeQuit {
  FileNavigationItem *topItem = [navBar topItem];
	NSString *filename = [topItem path];
  GSLog(@"Saving last browser path at shutdown: %@", filename);
  [defaults setLastBrowserPath:filename];
  
  // Need to kick the top-most EBookView.  It doesn't clean up on its own at shutdown.
  UIView *top = [navBar topView];
  if([top respondsToSelector:@selector(saveBookPosition)]) {
    EBookView *eb = (EBookView*)top;
    [eb saveBookPosition];
  }
  
	[defaults synchronize];
  
  GSLog(@"Books is terminating.");
  GSLog(@"========================================================");
}

- (void) applicationWillSuspend {
	[self cleanUpBeforeQuit];
}

// FIXME: Seems like this text stuff should be purely in the EBookView class.
- (void)embiggenText:(UINavBarButton *)button {
	if (![button isPressed]) {// mouse up events only, kids!
		[(EBookView*)[navBar topView] embiggenText];
		[defaults setTextSize:[(EBookView*)[navBar topView] textSize]];
	}
}

- (void)ensmallenText:(UINavBarButton *)button {
	if (![button isPressed]) {// mouse up events only, kids!
		[(EBookView*)[navBar topView] ensmallenText];
		[defaults setTextSize:[(EBookView*)[navBar topView] textSize]];
	}
}

- (void)invertText:(UINavBarButton *)button {
  if (![button isPressed]) { // mouse up events only, kids!
		textInverted = !textInverted;
		[(EBookView*)[navBar topView] invertText:textInverted];
		[defaults setInverted:textInverted];
		[self toggleStatusBarColor];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		[(EBookView*)[navBar topView] setFrame:rect];
	}	
}

- (void)pageDown:(UINavBarButton *)button {
	if (![button isPressed]) {
		[(EBookView*)[navBar topView] pageDownWithTopBar:![defaults navbar]
						   bottomBar:![defaults toolbar]];
	}	
}

- (void)pageUp:(UINavBarButton *)button {
	if (![button isPressed]) {
		[(EBookView*)[navBar topView] pageUpWithTopBar:![defaults navbar]
						 bottomBar:![defaults toolbar]];
	}	
}

/**
 * Advance to the next chapter, either using chapterdHtml or moving to the
 * next file in the file browser.
 */
- (void)chapForward:(UINavBarButton *)button {
	if (![button isPressed]) {
		if ([(EBookView*)[navBar topView] gotoNextSubchapter] == YES) {
			[navBar hide];
			[bottomNavBar hide];
		} else {
			NSString *nextFile = [[navBar topBrowser] fileAfterFileNamed:[defaults lastBrowserPath]];
			if(nextFile != nil) {
        UIView *newView = [self showDocumentAtPath:nextFile];
				FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithDocument:nextFile view:newView];
				[navBar replaceTopNavigationItem:tempItem];
				[tempItem release];
			}
		}
	}	
}

/**
 * Retreat to the last chapter, either using chapteredHtml or moving
 * to the next file in the file browser.
 */
- (void)chapBack:(UINavBarButton *)button {
	if (![button isPressed]) {
		if ([(EBookView*)[navBar topView] gotoPreviousSubchapter] == YES) {
			[navBar hide];
			[bottomNavBar hide];
		} else {
      FileBrowser *fb = [navBar topBrowser];
			NSString *prevFile = [fb fileBeforeFileNamed:[defaults lastBrowserPath]];
			if(nil != prevFile) {
        UIView *newView = [self showDocumentAtPath:prevFile];
				FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithDocument:prevFile view:newView];
				[navBar replaceTopNavigationItem:tempItem];
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
	struct CGRect rect = [mainView bounds];
	[navBar release]; //BCC in case this is not the first time this method is called
	navBar = [[HideableNavBar alloc] initWithFrame:
            CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f) delegate:self transitionView:transitionView];

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
    [bottomNavBar hide];
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

- (void)dealloc {
	[navBar release];
	[bottomNavBar release];
	[mainView release];
//	[progressIndicator release];
	[defaults release];
	[minusButton release];
	[plusButton release];
	[invertButton release];
	[rotateButton release];
  [m_documentExtensions release];
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
  /* This is going to be a disaster to fix all the views!
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
		[self refreshTextViewFromDefaultsToolbarsOnly];
		[textView setDelegate:self];
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

		//[navBar showTopNavBar:NO];
		//[navBar show];
		[bottomNavBar hide];
	}
//	
*/
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

/**
 * Ensure that the preferences screen can't be shown multiple times while the animation is in progress.
 */
- (void) preferenceAnimationDidFinish {
	[prefsButton setEnabled:true];
}
@end
