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

    defaults = [[BooksDefaultsController alloc] init];

    window = [[UIWindow alloc] initWithContentRect: rect];

    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];

    mainView = [[UIView alloc] initWithFrame: rect];

    navBar = [[HideableNavBar alloc] initWithFrame:
        CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];

    [navBar setDelegate:self];
    [navBar setBrowserDelegate:self];
    [navBar setExtensions:[NSArray arrayWithObjects:@"", @"txt", @"htm", @"html", nil]];
    [navBar hideButtons];

    [navBar disableAnimation];

    prefsButton = [[UINavBarButton alloc] initWithFrame: 
					    CGRectMake(275,9,40,30)];
    [prefsButton setAutosizesToFit:NO];							
    [prefsButton setImage:[self navBarImage:@"prefs_up"] forState:0];
    [prefsButton setImage:[self navBarImage:@"prefs_down"] forState:1];
    [prefsButton setDrawContentsCentered:YES];
    [prefsButton addTarget:self action:@selector(showPrefs:) forEvents: (255)];
    [prefsButton setNavBarButtonStyle:0];
    [prefsButton drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
    [navBar addSubview:prefsButton];
    [prefsButton setEnabled:YES];
    [navBar setRightMargin:45];

    bottomNavBar = [[HideableNavBar alloc] initWithFrame:
       CGRectMake(rect.origin.x, rect.size.height - 48.0f, 
		  rect.size.width, 48.0f)];

    [bottomNavBar setBarStyle:0];
    [bottomNavBar setDelegate:self];

    minusButton = [[UINavBarButton alloc] initWithFrame:
       					   CGRectMake(5,9,40,30)];
    [minusButton setAutosizesToFit:NO];
    [minusButton setImage:[self navBarImage:@"emsmall_up"] forState:0];
    [minusButton setImage:[self navBarImage:@"emsmall_down"] forState:1];
    [minusButton setNavBarButtonStyle:0];
    [minusButton setDrawContentsCentered:YES];
    [minusButton addTarget:self action:@selector(ensmallenText:) forEvents:(255)];
    [bottomNavBar addSubview:minusButton];
    [minusButton setEnabled:YES];

    plusButton = [[UINavBarButton alloc] initWithFrame:
	      				   CGRectMake(45,9,40,30)];
    [plusButton setAutosizesToFit:NO];
    [plusButton setImage:[self navBarImage:@"embig_up"] forState:0];
    [plusButton setImage:[self navBarImage:@"embig_down"] forState:1];
    [plusButton setDrawContentsCentered:YES];
    [plusButton addTarget:self action:@selector(embiggenText:) forEvents: (255)];
    [plusButton setNavBarButtonStyle:0];
    [bottomNavBar addSubview:plusButton];
    [plusButton setEnabled:YES];

    invertButton = [[UINavBarButton alloc] initWithFrame: 
					     CGRectMake(88,9,40,30)];
    [invertButton setAutosizesToFit:NO];							
    [invertButton setImage:[self navBarImage:@"inv_up"] forState:0];
    [invertButton setImage:[self navBarImage:@"inv_down"] forState:1];
    [invertButton setDrawContentsCentered:YES];
    [invertButton addTarget:self action:@selector(invertText:) forEvents: (255)];
    [invertButton setNavBarButtonStyle:0];
    [invertButton drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
    [bottomNavBar addSubview:invertButton];
    [invertButton setEnabled:YES];

	// Need to wrap this in a default vaule condition.
	// Crap, need to move all this button crud into something nicer.
	
    downButton = [[UINavBarButton alloc] initWithFrame: 
					     CGRectMake(275,9,40,30)];
    [downButton setAutosizesToFit:NO];							
    [downButton setImage:[self navBarImage:@"down_up"] forState:0];
    [downButton setImage:[self navBarImage:@"down_down"] forState:1];
    [downButton setDrawContentsCentered:YES];
    [downButton addTarget:self action:@selector(pageDown:) forEvents: (255)];
    [downButton setNavBarButtonStyle:0];
    [downButton drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
    [bottomNavBar addSubview:downButton];
    [downButton setEnabled:YES];

    upButton = [[UINavBarButton alloc] initWithFrame: 
					     CGRectMake(235,9,40,30)];
    [upButton setAutosizesToFit:NO];							
    [upButton setImage:[self navBarImage:@"up_up"] forState:0];
    [upButton setImage:[self navBarImage:@"up_down"] forState:1];
    [upButton setDrawContentsCentered:YES];
    [upButton addTarget:self action:@selector(pageUp:) forEvents: (255)];
    [upButton setNavBarButtonStyle:0];
    [upButton drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
    [bottomNavBar addSubview:upButton];
    [upButton setEnabled:YES];
	
	rightButton = [[UINavBarButton alloc] initWithFrame: 
					     CGRectMake(192,9,40,30)];
    [rightButton setAutosizesToFit:NO];							
    [rightButton setImage:[self navBarImage:@"right_up"] forState:0];
    [rightButton setImage:[self navBarImage:@"right_down"] forState:1];
    [rightButton setDrawContentsCentered:YES];
    [rightButton addTarget:self action:@selector(chapForward:) forEvents: (255)];
    [rightButton setNavBarButtonStyle:0];
    [rightButton drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
    [bottomNavBar addSubview:rightButton];
    [rightButton setEnabled:YES];
	
    leftButton = [[UINavBarButton alloc] initWithFrame: 
					     CGRectMake(152,9,40,30)];
    [leftButton setAutosizesToFit:NO];							
    [leftButton setImage:[self navBarImage:@"left_up"] forState:0];
    [leftButton setImage:[self navBarImage:@"left_down"] forState:1];
    [leftButton setDrawContentsCentered:YES];
    [leftButton addTarget:self action:@selector(chapBack:) forEvents: (255)];
    [leftButton setNavBarButtonStyle:0];
    [leftButton drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
    [bottomNavBar addSubview:leftButton];
    [leftButton setEnabled:YES];

    textView = [[EBookView alloc] 
        initWithFrame:
          CGRectMake(0, 0, rect.size.width, rect.size.height)];

    [self refreshTextViewFromDefaults];
	

    recentFile = [defaults fileBeingRead];
    readingText = [defaults readingText];

    if (readingText)
      {
	if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile])
	  {
	    [textView loadBookWithPath:recentFile];
	    
	    //NSLog(@"lastScrollPoint %f\n", (float)[defaults lastScrollPoint]);
	    
	  }
	else
	  {  // Recent file has been deleted!  RESET!
	    readingText = NO;
	    [defaults setLastScrollPoint:0];
	    [defaults setReadingText:NO];
	    [defaults setFileBeingRead:@""];
	    [defaults setLastBrowserPath:EBOOK_PATH];
	  }
      }

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
	UINavigationItem *tempItem = [[UINavigationItem alloc]
	        initWithTitle:[[recentFile lastPathComponent] 
				stringByDeletingPathExtension]];
	[navBar pushNavigationItem:tempItem withView:textView];

	// Deprecated: We hide the toolbar now when in the browser.
	/*
	[plusButton setEnabled:YES];
	[minusButton setEnabled:YES];
	[invertButton setEnabled:YES];
	*/
	
	[tempItem release];
      }


    [tempArray release];

    [navBar enableAnimation];
    doneLaunching = YES;

}

- (void)heartbeatCallback:(id)unused
{
  if (!transitionHasBeenCalled)
    {
      if ((textView != nil) && (defaults != nil))
	{
	  [textView scrollPointVisibleAtTopLeft:
		      CGPointMake(0.0f, (float)[defaults lastScrollPoint]) animated:NO];
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
  else
    {
      readingText = YES;
      UINavigationItem *tempItem = [[UINavigationItem alloc]
		        initWithTitle:[[file lastPathComponent]
					stringByDeletingPathExtension]];
      if (!([[textView currentPath] isEqualToString:file]))
	{
	  NSLog(@"Loading %@...", file);	  
	  [textView loadBookWithPath:file];
	  NSLog(@"Setting the scroll point...");
	  [defaults setLastScrollPoint:1];
	  transitionHasBeenCalled = NO;
	}
      // Slight optimization.  If the file is already loaded,
      // don't bother reloading.
      [navBar pushNavigationItem:tempItem withView:textView];
      NSLog(@"back in BooksApp...");

	  // Deprecated: We hide the toolbar now when in the browser.
      /*
	  [minusButton setEnabled:YES];
      [plusButton setEnabled:YES];
      [invertButton setEnabled:YES];
      */

	  NSLog(@"did the buttons...");
      [tempItem release];
      NSLog(@"released tempItem...");
      [navBar hide:NO];
      [bottomNavBar hide:NO];
      NSLog(@"Marines, we are leaving...");
    }
}

// Deprecated?  NO.--zbg
- (void)textViewDidGoAway:(id)sender
{
  NSLog(@"textViewDidGoAway start...");
  struct CGRect selectionRect = [textView visibleRect];
  NSLog(@"called visiblerect, origin.y is %d ", (unsigned int)selectionRect.origin.y);
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y];
  NSLog(@"set defaults ");
  readingText = NO;
  [bottomNavBar hide:YES];

  // Depreciated: We hide the toolbar now when in the browser.
  /*
  [minusButton setEnabled:NO];
  [plusButton setEnabled:NO];
  [invertButton setEnabled:NO];
  */
  
  NSLog(@"end.\n");
}
/*
- (void)notifyDidCompleteTransition:(id)unused
  // Delegate method?
{
  
  if (!transitionHasBeenCalled)
    {
      NSLog(@"notifyDidComplete\n");
      transitionHasBeenCalled = YES;
    }
}
*/
- (void) applicationWillSuspend
{

  struct CGRect selectionRect;
  [defaults setFileBeingRead:[textView currentPath]];
  selectionRect = [textView visibleRect];
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y];
  [defaults setReadingText:readingText];
  [defaults setLastBrowserPath:[navBar topBrowserPath]];
  [defaults synchronize];

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
      struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
      rect.origin.x = rect.origin.y = 0.0f;
      [textView setFrame:rect];
    }	
}

- (void)pageDown:(UINavBarButton *)button 
{
  if (![button isPressed])
    {
		[textView pageDown];
    }	
}

- (void)pageUp:(UINavBarButton *)button 
{
  if (![button isPressed])
    {
		[textView pageUp];
    }	
}

- (void)chapForward:(UINavBarButton *)button 
{
  if (![button isPressed])
    {
		// TODO: Put chapter forward code here;
    }	
}

- (void)chapBack:(UINavBarButton *)button 
{
  if (![button isPressed])
    {
		// TODO: Put chapter back code here;
    }	
}

- (UIImage *)navBarImage:(NSString *)name
{
  NSBundle *bundle = [NSBundle mainBundle];
  imgPath = [bundle pathForResource:name ofType:@"png"];
  buttonImg = [[UIImage alloc]initWithContentsOfFile:imgPath];
  return buttonImg;
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

- (void)refreshTextViewFromDefaults
{
    [textView setTextSize:[defaults textSize]];

    textInverted = [defaults inverted];
    [textView invertText:textInverted];

    [textView setTextFont:[defaults textFont]];
	
    if (readingText)
      {  // Let's avoid the weird toggle behavior.
	[navBar hide:NO];
	[bottomNavBar hide:NO];
      }

    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
    [textView setFrame:rect];
}

- (void) dealloc
{
  [navBar release];
  [bottomNavBar release];
  [mainView release];
  // textView = nil;
  [textView release];
  [defaults release];
  [buttonImg release];
  [minusButton release];
  [plusButton release];
  [invertButton release];
  [super dealloc];
}

@end
