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


@implementation BooksApp

- (void) applicationDidFinishLaunching: (id) unused
{
    NSString *recentFile;

    UIWindow *window;

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
    [navBar hideButtons];
    //    [navBar setPrompt:@"Choose a book..."];
    [navBar disableAnimation];

    bottomNavBar = [[HideableNavBar alloc] initWithFrame:
       CGRectMake(rect.origin.x, rect.size.height - 48.0f, rect.size.width, 48.0f)];

    [bottomNavBar setBarStyle:0];
    [bottomNavBar setDelegate:self];

    minusButton = [[UINavBarButton alloc] initWithFrame:
       					   CGRectMake(5,8,32,32)];
    [minusButton setAutosizesToFit:NO];
    [minusButton setTitle:@"-"];
    [minusButton setNavBarButtonStyle:0];
    [minusButton setDrawContentsCentered:YES];
    [minusButton addTarget:self action:@selector(ensmallenText:) forEvents:(255)];
    [bottomNavBar addSubview:minusButton];
    [minusButton setEnabled:NO];

    plusButton = [[UINavBarButton alloc] initWithFrame:
	      				   CGRectMake(40,8,32,32)];
    [plusButton setAutosizesToFit:NO];
    [plusButton setTitle:@"+"];
    [plusButton setDrawContentsCentered:YES];
    [plusButton addTarget:self action:@selector(embiggenText:) forEvents: (255)];
    [plusButton setNavBarButtonStyle:0];
    [bottomNavBar addSubview:plusButton];
    [plusButton setEnabled:NO];

    plainTextView = [[EBookView alloc] 
        initWithFrame:
          CGRectMake(0, 0, rect.size.width, rect.size.height)];

    HTMLTextView = [[EBookView alloc] 
        initWithFrame:
          CGRectMake(0, 0, rect.size.width, rect.size.height)];

    [HTMLTextView setTextSize:[defaults textSize]];
    [plainTextView setTextSize:[defaults textSize]];

    textView = HTMLTextView;

    recentFile = [defaults fileBeingRead];

    if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile] && 
	([defaults topViewIndex] == TEXTVIEW))
      {
	if ([[recentFile pathExtension] isEqualToString:@"txt"])
	  textView = plainTextView;
	else
	  textView = HTMLTextView;

	[textView loadBookWithPath:recentFile];

	//NSLog(@"lastScrollPoint %f\n", (float)[defaults lastScrollPoint]);

      }
    else
      {  // Recent file has been deleted!  RESET!
	[defaults setLastScrollPoint:0];
	[defaults setTopViewIndex:BROWSERVIEW];
	[defaults setFileBeingRead:@""];
      }



    browserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0.0f, rect.size.width, rect.size.height)];

    chapterBrowserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0.0f, rect.size.width, rect.size.height)];

    transitionView = [[UITransitionView alloc] initWithFrame:
       CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)];
    [transitionView setDelegate:self];

    booksItem = [[EBookNavItem alloc] initWithTitle:@"Books" view:browserView];
    chaptersItem = [[EBookNavItem alloc] initWithTitle:@"Chapters" view:chapterBrowserView];
    bookItem = [[EBookNavItem alloc] initWithTitle:[[[textView currentPath] lastPathComponent] stringByDeletingPathExtension] view:textView];

    [browserView setExtensions:[NSArray arrayWithObjects:@"", @"txt", @"html", @"htm", nil]];
    [chapterBrowserView setExtensions:[NSArray arrayWithObjects:@"txt", @"html", @"htm", nil]];


    [booksItem setDelegate:self];
    [chaptersItem setDelegate:self];
    [bookItem setDelegate:self];

    bookHasChapters = NO;
    readingText = NO;



    path = @"/var/root/Media/EBooks/";

    [browserView setPath:path];
    [browserView setDelegate:self];
    [chapterBrowserView setDelegate:self];


    [window setContentView: mainView];
    [mainView addSubview:transitionView];
    [mainView addSubview:navBar];
    [mainView addSubview:bottomNavBar];

    [navBar pushNavigationItem:booksItem];
    if ([defaults topViewIndex] > BROWSERVIEW)
      {
	[navBar pushNavigationItem:chaptersItem];
	bookHasChapters = YES;  // FIXME.  
	// We might be reading a book without chapters!
      }
    if ([defaults topViewIndex] == TEXTVIEW)
      {
	[navBar pushNavigationItem:bookItem];
	readingText = YES;
      }
    switch ([defaults topViewIndex]) 
      {
      case BROWSERVIEW:
	[transitionView transition:1 toView:browserView];
	break;
      case CHAPTERBROWSERVIEW:
	[transitionView transition:1 toView:chapterBrowserView];
	[chapterBrowserView setPath:[[textView currentPath] stringByDeletingLastPathComponent]];
	break;
      case TEXTVIEW:
	[transitionView transition:1 toView:textView];

	//FIXME: The following fails if we're reading a book without chapters.
	//This may have to wait until the browser architecture has
	//been rewritten.
	[chapterBrowserView setPath:[[textView currentPath] stringByDeletingLastPathComponent]];
	[plusButton setEnabled:YES];
	[minusButton setEnabled:YES];
	break;
      }

    [plainTextView setHeartbeatDelegate:self];
    [HTMLTextView setHeartbeatDelegate:self];

    [navBar enableAnimation];
    doneLaunching = YES;

}
/*
- (void)toggleNavbars
{
  struct CGRect appRect = [UIHardware fullScreenApplicationContentRect];
  struct CGRect topNavbarOn = CGMakeRect(appRect.origin.x, appRect.origin.y, appRect.size.width, 48.0f);
  struct CGRect topNavbarOn = CGMakeRect(appRect.origin.x - 48.0, appRect.origin.y, appRect.size.width, 48.0f);

}
*/
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
  [navBar hide];
  [bottomNavBar hide];
}

- (void)toggleNavbars
{
  /*  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0.0f;
  struct CGRect newRect = CGRectMake(0.0f, 48.0f, rect.size.width, rect.size.height - 48.0f);
  if ([navBar hidden])
    {
      [textView setFrame:newRect];
    }
  else
    {
      [textView setFrame:rect];
    }
  */
  [navBar toggle];
  [bottomNavBar toggle];
}

- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:file isDirectory:&isDir] && isDir)
      {
	[chapterBrowserView setPath:file];
	[chaptersItem setTitle:[[file lastPathComponent] stringByDeletingPathExtension]];

	[navBar showBackButton:YES animated:YES];
	[navBar pushNavigationItem:chaptersItem];

	bookHasChapters = YES;
      }
    else
      {
	NSString *leftTitle;
	if (!([[textView currentPath] isEqualToString:file]))
	  {
	    if ([[file pathExtension] isEqualToString:@"txt"])
	      textView = plainTextView;
	    else
	      textView = HTMLTextView;
	    [textView loadBookWithPath:file];
	    [defaults setLastScrollPoint:1];
	    //[textView scrollPointVisibleAtTopLeft:CGPointMake(0.0f, 0.0f)];
	    transitionHasBeenCalled = NO;
	  }
	// Slight optimization.  If the file is already loaded,
	// don't bother reloading.

	if (bookHasChapters)
	  leftTitle = @"Chapters";
	else
	  leftTitle = @"Books";
	[bookItem setTitle:[[file lastPathComponent] stringByDeletingPathExtension]];

	[navBar showBackButton:YES animated:YES];
	[navBar pushNavigationItem:bookItem];
	[minusButton setEnabled:YES];
	[plusButton setEnabled:YES];

	[textView becomeFirstResponder];
	readingText = YES;

      }
}

//The following method may be unneeded.
// FIXME: make the nav-bar prettier!
- (void)navigationBar:(UINavigationBar *)thebar buttonClicked:(int)button {
  switch (button) {
  case 0:// right
    if (readingText)
      {
	[textView embiggenText]; // It's a perfectly cromulent method.
      }
    break;
  case 1:// left
    {
      if (bookHasChapters && readingText)
	{
	  [navBar popNavigationItem];
	  [navBar showButtonsWithLeftTitle:@"Books" rightTitle:nil leftBack:YES];
	  [transitionView transition:2 toView:chapterBrowserView];
	  readingText = NO;
	}
      else
	{
	  [navBar popNavigationItem];
	  [navBar hideButtons];
	  [transitionView transition:2 toView:browserView];
	  bookHasChapters = NO;
	  readingText = NO;
	}
    }
  }
}

- (void)transitionToView:(id)view
{
  struct CGRect selectionRect;
  int transType;
  struct CGRect fullRect = [UIHardware fullScreenApplicationContentRect];
  fullRect.origin.x = fullRect.origin.y = 0.0f;
  if (doneLaunching)
    {
      if ([view isEqual:browserView]) // we must be going backward
	{
	  readingText = NO;
	  [minusButton setEnabled:NO];
	  [plusButton setEnabled:NO];
	  transType = 2;
	}
      else if ([view isEqual:chapterBrowserView]) // eep! we don't know which way!
	{

	  if (readingText == YES)
	    {
	      selectionRect = [textView visibleRect];
	      [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y];
	      [minusButton setEnabled:NO];
	      [plusButton setEnabled:NO];
	      transType = 2;
	    }
	  else
	    {
	      transType = 1; 
	    }
	}
      else
	{
	  view = textView;  // this is needed because of the txt/html fugliness

	  transType = 1;
	  //[textView scrollPointVisibleAtTopLeft:CGPointMake(selectionRect.origin.x, (float)[defaults lastScrollPoint]) animated:YES];
	  [self hideNavbars];
	  [minusButton setEnabled:YES];
	  [plusButton setEnabled:YES];
	}
      [transitionView transition:transType toView:view];
    }
}

- (void)notifyDidCompleteTransition:(id)unused
  // Delegate method?
{
  
  if (!transitionHasBeenCalled)
    {
      NSLog(@"notifyDidComplete\n");
      transitionHasBeenCalled = YES;
    }
}

- (void) applicationWillSuspend
{

  struct CGRect selectionRect;
  [defaults setFileBeingRead:[textView currentPath]];
  selectionRect = [textView visibleRect];
  [defaults setLastScrollPoint:(unsigned int)selectionRect.origin.y];

  if (readingText)
    [defaults setTopViewIndex:TEXTVIEW];
  else
    [defaults setTopViewIndex:BROWSERVIEW];
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

- (void) dealloc
{
  [booksItem release];
  [chaptersItem release];
  [bookItem release];
  [navBar release];
  [mainView release];
  textView = nil;
  [plainTextView release];
  [HTMLTextView release];
  [browserView release];
  [defaults release];
  [minusButton release];
  [plusButton release];
  [super dealloc];
}

@end
