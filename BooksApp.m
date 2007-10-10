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
    imageSplashed = NO;
    defaults = [[BooksDefaultsController alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self
		 selector:@selector(updateToolbar:)
		 name:@"toolbarDefaultsChanged"
					      object:nil];

    window = [[UIWindow alloc] initWithContentRect: rect];

    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
    struct CGSize progsize = [UIProgressIndicator defaultSizeForStyle:0];
    progressIndicator = [[UIProgressIndicator alloc] 
			  initWithFrame:CGRectMake((320-progsize.width)/2,
						   (460-progsize.height)/2,
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

    imageView = nil;

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
	    NSString *coverart = [EBookImageView coverArtForBookPath:recentFile];

	    UINavigationItem *tempItem = [[UINavigationItem alloc]
		       initWithTitle:[[recentFile lastPathComponent] 
				stringByDeletingPathExtension]];
	    if (nil == coverart)
	      {
		[progressIndicator setStyle:![defaults inverted]];
		[mainView addSubview:progressIndicator];
		[progressIndicator startAnimation];
		imageView = nil;
		[navBar pushNavigationItem:tempItem withView:textView];
		[textView loadBookWithPath:recentFile numCharacters:(265000/([textView textSize]*[textView textSize]))];
		textViewNeedsFullText = YES;
	      }
	    else
	      {
		imageView = [[EBookImageView alloc] initWithContentsOfFile:coverart withinSize:CGSizeMake(320,460)];
		[mainView addSubview:imageView];
		[mainView addSubview:progressIndicator];
		[progressIndicator startAnimation];
		[progressIndicator setStyle:0];
		
		[navBar pushNavigationItem:tempItem withView:textView];
		[textView setCurrentPathWithoutLoading:recentFile];
		textViewNeedsFullText = YES;
		imageSplashed = YES;
	      }

	    [tempItem release];
	    [navBar hide:NO];
	    [bottomNavBar hide:NO];
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
  if (imageSplashed)
    {
      [textView loadBookWithPath:[textView currentPath]];
      textViewNeedsFullText = NO;
    }
  if ((textViewNeedsFullText) && ![transitionView isTransitioning])
    {
      [textView loadBookWithPath:[textView currentPath]];
      textViewNeedsFullText = NO;
      [progressIndicator stopAnimation];
      [progressIndicator removeFromSuperview];
    }
  if ((!transitionHasBeenCalled)/* && ![transitionView isTransitioning]*/)
    {
      if ((textView != nil) && (defaults != nil))
	{
	  //[self refreshTextViewFromDefaults];
	  [textView scrollPointVisibleAtTopLeft:
		      CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	  [progressIndicator stopAnimation];
	  [progressIndicator removeFromSuperview];
	  [imageView removeFromSuperview];
	  imageSplashed = NO;
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
  [self hideSlider];
}

- (void)toggleNavbars
{
  [navBar toggle];
  [bottomNavBar toggle];
  if (nil == scrollerSlider)
    [self showSlider];
  else
    [self hideSlider];
}

- (void)showSlider
{
  if (nil == scrollerSlider)
    {
      CGRect rect = CGRectMake(0, 48, 320, 48);
      scrollerSlider = [[UISliderControl alloc] initWithFrame:rect];
      [mainView addSubview:scrollerSlider];
    }
  if (animator != nil)
      [animator release];
  animator = [[UIAnimator alloc] init];
  if (alpha != nil)
    [alpha release];
  alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
  [alpha setStartAlpha:0];
  [alpha setEndAlpha:1];
  CGRect theWholeShebang = [[textView _webView] frame];
  CGRect visRect = [textView visibleRect];
  int endPos = (int)theWholeShebang.size.height - 460;
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
  [animator addAnimation:alpha withDuration:0.25 start:YES];
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
	  [defaults setLastScrollPoint:0 forFile:file]; //Just to get rid of the "unread" circle
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
	      int lastPt = [defaults lastScrollPointForFile:file];
	      BOOL didLoadAll = NO;
	      int numScreens = (lastPt / 460) + 1;  // how many screens down are we?
	      int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));
	      [textView loadBookWithPath:file numCharacters:numChars didLoadAll:&didLoadAll];
	      [textView scrollPointVisibleAtTopLeft:
	          CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
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
  //  NSLog(@"textViewDidGoAway start...");
  struct CGRect selectionRect = [textView visibleRect];
  //  NSLog(@"called visiblerect, origin.y is %d ", (unsigned int)selectionRect.origin.y);
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y
	    forFile:[textView currentPath]];
  //  NSLog(@"set defaults ");
  readingText = NO;
  [bottomNavBar hide:YES];
  if (scrollerSlider != nil)
    [self hideSlider];
  NSLog(@"end.\n");
}

- (void)applicationWillTerminate
{
  // Let's see if this defeats the Dock.app bug.
  struct CGRect selectionRect;
  [defaults setFileBeingRead:[textView currentPath]];
  selectionRect = [textView visibleRect];
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y
	    forFile:[textView currentPath]];
  [defaults setReadingText:readingText];
  [defaults setLastBrowserPath:[navBar topBrowserPath]];
  [defaults synchronize];
}

- (void) applicationWillSuspend
{
  struct CGRect selectionRect;
  [defaults setFileBeingRead:[textView currentPath]];
  selectionRect = [textView visibleRect];
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y
	    forFile:[textView currentPath]];
  [defaults setReadingText:readingText];
  [defaults setLastBrowserPath:[navBar topBrowserPath]];
  [defaults synchronize];
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
      if ((nil != nextFile) && [nextFile isReadableTextFilePath])
	{
	  [self hideSlider];
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
	  BOOL didLoadAll = NO;
	  int numScreens = (lastPt / 460) + 1;  // how many screens down are we?
	  int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));
	  [textView loadBookWithPath:nextFile numCharacters:numChars
		    didLoadAll:&didLoadAll];
	  [textView scrollPointVisibleAtTopLeft:
		      CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	  textViewNeedsFullText = !didLoadAll;
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
      if ((nil != prevFile) && [prevFile isReadableTextFilePath])
	{
	  [self hideSlider];
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
	  //[progressHUD show:YES];
	  [textView loadBookWithPath:prevFile];
	  [textView scrollPointVisibleAtTopLeft:
		      CGPointMake(0.0f, (float)[defaults lastScrollPointForFile:[textView currentPath]]) animated:NO];
	  //[progressHUD show:NO];
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
    [navBar setExtensions:[NSArray arrayWithObjects:@"", @"txt", @"htm", @"html", @"pdb", @"jpg", @"png", @"gif", nil]];
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
  float scrollPercentage;
  if (!toolbarsOnly)
    {
      [textView setTextSize:[defaults textSize]];
      
      textInverted = [defaults inverted];
      [textView invertText:textInverted];

      struct CGRect overallRect = [[textView _webView] frame];
      NSLog(@"overall height: %f", overallRect.size.height);
      struct CGRect visRect = [textView visibleRect];
      scrollPercentage = visRect.origin.y / overallRect.size.height;
      NSLog(@"scroll percent: %f",scrollPercentage);
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
	//	[textView loadBookWithPath:[textView currentPath]];
	[textView setFrame:rect];
	struct CGRect overallRect = [[textView _webView] frame];
      NSLog(@"overall height: %f", overallRect.size.height);
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
  [super dealloc];
}

@end
