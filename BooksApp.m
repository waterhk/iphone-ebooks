/* ------ BooksApp, written by Zachary Brewster-Geisz
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

@implementation BooksApp

- (void) applicationDidFinishLaunching: (id) unused
{
    NSString *recentFile;

    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;

    doneLaunching = NO;

    transitionHasBeenCalled = NO;

    navbarsAreOn = YES;

    textViewNeedsFullText = NO;

    defaults = [[BooksDefaultsController alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self
		 selector:@selector(updateToolbar:)
		 name:@"toolbarDefaultsChanged"
					      object:nil];

    window = [[UIWindow alloc] initWithContentRect: rect];

    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
    progressHUD = [[UIProgressHUD alloc] initWithWindow:window];
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
    [mainView addSubview:transitionView];
    [mainView addSubview:navBar];
    [mainView addSubview:bottomNavBar];
    if (!readingText) 
      [bottomNavBar hide:YES];

    [textView setHeartbeatDelegate:self];

    [navBar setTransitionView:transitionView];
    [transitionView setDelegate:self];

    UINavigationItem *tempItem = [[UINavigationItem alloc] initWithTitle:@"Books"];
    [navBar pushNavigationItem:tempItem withBrowserPath:EBOOK_PATH];

    NSString *tempString = [defaults lastBrowserPath];
    NSMutableArray *tempArray = [[NSMutableArray alloc] init]; 

    if (![tempString isEqualToString:EBOOK_PATH])
      {
	[tempArray addObject:[NSString stringWithString:tempString]];
	while ((![(tempString = [tempString stringByDeletingLastPathComponent])
		   isEqualToString:EBOOK_PATH]) && 
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
	    [navBar pushNavigationItem:tempItem withView:textView];

	    [tempItem release];
	    [navBar hide:NO];
	    [bottomNavBar hide:NO];
	    [textView loadBookWithPath:recentFile numCharacters:(265000/([textView textSize]*[textView textSize]))];
	    textViewNeedsFullText = YES;
	    [progressHUD show:YES];
	    //NSLog(@"lastScrollPoint %f\n", (float)[defaults lastScrollPoint]);
	    
	  }
	else
	  {  // Recent file has been deleted!  RESET!
	    readingText = NO;
	    [defaults setLastScrollPoint:0];
	    [defaults setReadingText:NO];
	    [defaults setFileBeingRead:@""];
	    [defaults setLastBrowserPath:EBOOK_PATH];
	    [defaults removeScrollPointForFile:recentFile];
	  }
      }


    [tempArray release];

    [navBar enableAnimation];

    //    [self setStatusBarCustomText:@"?"];
    doneLaunching = YES;

}

- (void)heartbeatCallback:(id)unused
{
  if ((textViewNeedsFullText) && ![transitionView isTransitioning])
    {
      [textView loadBookWithPath:[textView currentPath]];
      textViewNeedsFullText = NO;
      [progressHUD show:NO];
    }
  if (!transitionHasBeenCalled)
    {
      if ((textView != nil) && (defaults != nil))
	{
	  //	  [self refreshTextViewFromDefaults];
	  [textView scrollPointVisibleAtTopLeft:
		      CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	  transitionHasBeenCalled = YES;
	}
    }
}

- (void)hideNavbars
{
  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0.0f;
  [textView setFrame:rect];
  [navBar hide:NO];
  [bottomNavBar hide:NO];
}

- (void)toggleNavbars
{
  [navBar toggle];
  [bottomNavBar toggle];
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
	  int lastPt = [defaults lastScrollPointForFile:file];
	  if (0 == lastPt) // If we haven't been here before, let's try an optimized load.
	    {
	      [textView loadBookWithPath:file numCharacters:(265000/([textView textSize]*[textView textSize]))];
	      textViewNeedsFullText = YES;
	      //[progressHUD show:YES];
	    }
	  else
	    {
	      [progressHUD show:YES];
	      [textView loadBookWithPath:file];
	      [textView scrollPointVisibleAtTopLeft:
			  CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	      [progressHUD show:NO];
	    }
	  //	  [self refreshTextViewFromDefaults];
	}
      //NSLog(@"back in BooksApp...");

      //  NSLog(@"did the buttons...");
      [tempItem release];
      //NSLog(@"released tempItem...");
      [navBar hide:NO];
      if (![defaults toolbar])
	[bottomNavBar show];
      else
	[bottomNavBar hide:NO];
      //NSLog(@"Marines, we are leaving...");
    }
}

- (void)textViewDidGoAway:(id)sender
{
  //  NSLog(@"textViewDidGoAway start...");
  struct CGRect selectionRect = [textView visibleRect];
  //  NSLog(@"called visiblerect, origin.y is %d ", (unsigned int)selectionRect.origin.y);
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y
	    forFile:[textView currentPath]];
  //  NSLog(@"set defaults ");
  readingText = NO;
  [bottomNavBar hide:YES];

  NSLog(@"end.\n");
}

- (void) applicationWillSuspend
{
  /*
  //struct CGImage *defaultPNG =  [self createApplicationDefaultPNG];
  NSString *defaultPNGPath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"];
  struct CGRect snapshotRect = [self applicationSnapshotRectForOrientation:0];
  struct CGImage *defaultPNG = [textView createSnapshotWithRect:snapshotRect];
  //UIImage *defaultPNGImage = [[UIImage alloc] initWithImageRef:defaultPNG];

 NSData *imgData = [[NSData alloc] initWithBytes:*defaultPNG length:CGImageGetBytesPerRow(defaultPNG)*CGImageGetHeight(defaultPNG)];
  [imgData writeToFile:defaultPNGPath atomically:YES];
  */
  struct CGRect selectionRect;
  [defaults setFileBeingRead:[textView currentPath]];
  selectionRect = [textView visibleRect];
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y
	    forFile:[textView currentPath]];
  [defaults setReadingText:readingText];
  [defaults setLastBrowserPath:[navBar topBrowserPath]];
  [defaults synchronize];
  //[imgData release];
}

- (void)embiggenText:(UINavBarButton *)button
{
  if (![button isPressed]) // mouse up events only, kids!
    {
      [textView embiggenText];
      [defaults setTextSize:[textView textSize]];
    }
}

- (void)ensmallenText:(UINavBarButton *)button
{
  if (![button isPressed]) // mouse up events only, kids!
    {
      [textView ensmallenText];
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
      struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
      rect.origin.x = rect.origin.y = 0.0f;
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
  if (![button isPressed])
    {
      NSString *nextFile = [[navBar topBrowser] fileAfterFileNamed:[textView currentPath]];
      if (nil != nextFile)
	{
	  EBookView *tempView = textView;
	  struct CGRect visRect = [tempView visibleRect];
	  [defaults setLastScrollPoint:(unsigned int)visRect.origin.y
		    forFile:[tempView currentPath]];
	  textView = [[EBookView alloc] initWithFrame:[tempView frame]];
	  [textView setHeartbeatDelegate:self];

	  UINavigationItem *tempItem = 
	    [[UINavigationItem alloc] initWithTitle:
		   [[nextFile lastPathComponent] 
		     stringByDeletingPathExtension]];
	  [navBar pushNavigationItem:tempItem withView:textView];
	  [self refreshTextViewFromDefaults];
	  int lastPt = [defaults lastScrollPointForFile:nextFile];
	  if (0 == lastPt)
	    {
	      [textView loadBookWithPath:nextFile numCharacters:(265000/([textView textSize]*[textView textSize]))];
	      textViewNeedsFullText = YES;
	      //[progressHUD show:YES]; //nah, I don't like it there.
	    }
	  else
	    {
	      [progressHUD show:YES];
	      [textView loadBookWithPath:nextFile];
	      [textView scrollPointVisibleAtTopLeft:
			  CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	      [progressHUD show:NO];
	    }
	  [tempItem release];
	  [tempView autorelease];
	}
    }	
}

- (void)chapBack:(UINavBarButton *)button 
{
  if (![button isPressed])
    {
      NSString *prevFile = [[navBar topBrowser] fileBeforeFileNamed:[textView currentPath]];
      if (nil != prevFile)
	{
	  EBookView *tempView = textView;
	  struct CGRect visRect = [tempView visibleRect];
	  [defaults setLastScrollPoint:(unsigned int)visRect.origin.y
		    forFile:[tempView currentPath]];
	  textView = [[EBookView alloc] initWithFrame:[tempView frame]];
	  [textView setHeartbeatDelegate:self];
	  UINavigationItem *tempItem = 
	    [[UINavigationItem alloc] initWithTitle:
		   [[prevFile lastPathComponent] 
		     stringByDeletingPathExtension]];

	  [navBar pushNavigationItem:tempItem withView:textView reverseTransition:YES];
	  [self refreshTextViewFromDefaults];
	  [progressHUD show:YES];
	  [textView loadBookWithPath:prevFile];
	  [textView scrollPointVisibleAtTopLeft:
		      CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	  [progressHUD show:NO];
	  [tempItem release];
	  [tempView autorelease];
	}
    }	
}

// CHANGED: Moved navbar and toolbar setup here from applicationDidFinishLaunching

- (void)setupNavbar
{
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;

	navBar = [[HideableNavBar alloc] initWithFrame:
        CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];

    [navBar setDelegate:self];
    [navBar setBrowserDelegate:self];
    [navBar setExtensions:[NSArray arrayWithObjects:@"", @"txt", @"htm", @"html", nil]];
    [navBar hideButtons];

    [navBar disableAnimation];
    [navBar setRightMargin:45];

    prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(275,9,40,30) selector:@selector(showPrefs:) flipped:NO];

    [navBar addSubview:prefsButton];
}

- (void)setupToolbar
{
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;

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
		
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(192,9,40,30) selector:@selector(invertText:) flipped:NO];
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(235,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(275,9,40,30) selector:@selector(embiggenText:) flipped:NO];
	} else {
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(5,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(45,9,40,30) selector:@selector(embiggenText:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(88,9,40,30) selector:@selector(invertText:) flipped:NO];
		
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
    [button drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
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

- (void)updateToolbar:(NSNotification *)notification
{
	NSLog(@"%s Got toolbar update notification.", _cmd);
	[bottomNavBar removeFromSuperview];
	[self setupToolbar];
	[mainView addSubview:bottomNavBar];
}

- (void)setTextInverted:(BOOL)b
{
	textInverted = b;
}

- (void)showPrefs:(UINavBarButton *)button
{
  if (![button isPressed]) // mouseUp only
    {
	NSLog(@"Showing Preferences View");
	PreferencesController *prefsController = [[PreferencesController alloc] initWithAppController:self];
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
  if (!toolbarsOnly)
    {
      [textView setTextSize:[defaults textSize]];
      
      textInverted = [defaults inverted];
      [textView invertText:textInverted];

      [textView setTextFont:[defaults textFont]];
      
      [self toggleStatusBarColor];
    }
    if (readingText)
      {  // Let's avoid the weird toggle behavior.
	[navBar hide:NO];
	[bottomNavBar hide:NO];
      }
    else // not reading text
      [bottomNavBar hide:YES];

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
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	rect.origin.x = rect.origin.y = 0.0f;
	[textView setFrame:rect];
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
	if ([defaults inverted]) {
		[self setStatusBarMode:3 duration:0.25];
    } else {
		[self setStatusBarMode:0 duration:0.25];
	}
}

- (void) dealloc
{
  [navBar release];
  [bottomNavBar release];
  [mainView release];
  // textView = nil;
  [progressHUD release];
  [textView release];
  [defaults release];
  [buttonImg release];
  [minusButton release];
  [plusButton release];
  [invertButton release];
  [super dealloc];
}

@end
