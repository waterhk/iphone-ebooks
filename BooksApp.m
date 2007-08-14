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

    defaults = [[BooksDefaultsController alloc] init];

    window = [[UIWindow alloc] initWithContentRect: rect];

    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];

    mainView = [[UIView alloc] initWithFrame: rect];

    navBar = [[UINavigationBar alloc] initWithFrame:
        CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];

    [navBar setDelegate:self];
    [navBar hideButtons];
    //    [navBar setPrompt:@"Choose a book..."];
    [navBar enableAnimation];

    textView = [[EBookView alloc] 
        initWithFrame:
          CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    recentFile = [defaults fileBeingRead];

    if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile])
      {
	[textView loadBookWithPath:recentFile];
	//	[transitionView transition:1 toView:textView];
      }
    else
      {  // Recent file has been deleted!  RESET!
	//[defaults setLastScrollPoint:CGPointMake(0, 0)];
	[defaults setTopViewIndex:BROWSERVIEW];
	[defaults setFileBeingRead:@""];
      }

    browserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    chapterBrowserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    transitionView = [[UITransitionView alloc] initWithFrame:
       CGRectMake(rect.origin.x, 48.0f, rect.size.width, rect.size.height - 48.0f)];

    booksItem = [[EBookNavItem alloc] initWithTitle:@"Books" view:browserView];
    chaptersItem = [[EBookNavItem alloc] initWithTitle:@"Chapters" view:chapterBrowserView];
    bookItem = [[EBookNavItem alloc] initWithTitle:[[[textView currentPath] lastPathComponent] stringByDeletingPathExtension] view:textView];

    [browserView setExtensions:[NSArray arrayWithObjects:@"txt", @"html", @"htm", nil]];
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
    [mainView addSubview:navBar];
    [mainView addSubview:transitionView];

    [navBar pushNavigationItem:booksItem];
    if ([defaults topViewIndex] > BROWSERVIEW)
      {
	[navBar pushNavigationItem:chaptersItem];
	bookHasChapters = YES;  // FIXME.  
	// We might be reading a book without chapters!
      }
    if ([defaults topViewIndex] == TEXTVIEW)
      {
	NSLog(@"Hello thar!\n");
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
	break;
      case TEXTVIEW:
	[transitionView transition:1 toView:textView];
	break;
      }

    doneLaunching = YES;
}

- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:file isDirectory:&isDir] && isDir)
      {
	[chapterBrowserView setPath:file];
	[chaptersItem setTitle:[[file lastPathComponent] stringByDeletingPathExtension]];
	//	[chaptersItem setBackButtonTitle:@"Books"];
	[navBar showBackButton:YES animated:YES];
	[navBar pushNavigationItem:chaptersItem];
	//[navBar showButtonsWithLeftTitle:@"Books" rightTitle:nil leftBack:YES];
	//	[transitionView transition:1 toView:chapterBrowserView];
	bookHasChapters = YES;
      }
    else
      {
	NSString *leftTitle;
	if (!([[textView currentPath] isEqualToString:file]))
	  [textView loadBookWithPath:file];
	// Slight optimization.  If the file is already loaded,
	// don't bother reloading.
	//[textView scrollPointVisibleAtTopLeft:[defaults lastScrollPoint]];

	if (bookHasChapters)
	  leftTitle = @"Chapters";
	else
	  leftTitle = @"Books";
	[bookItem setTitle:[[file lastPathComponent] stringByDeletingPathExtension]];
	//[bookItem setBackButtonTitle:leftTitle];
	[navBar showBackButton:YES animated:YES];
	[navBar pushNavigationItem:bookItem];
	//[navBar showButtonsWithLeftTitle:leftTitle rightTitle:nil leftBack:YES];
	//[transitionView transition:1 toView:textView];
	[textView becomeFirstResponder];
	readingText = YES;
      }
}


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
  int transType;
  if (doneLaunching)
    {
      if ([view isEqual:browserView]) // we must be going backward
	{
	  readingText = NO;
	  NSLog(@"toview: browserView\n");
	  transType = 2;
	}
      else if ([view isEqual:textView]) // we must be going forward
	{
	  NSLog(@"toView:textview\n");
	  transType = 1;
	}
      else if ([view isEqual:chapterBrowserView]) // eep! we don't know which way!
	{
	  NSLog(@"toView: chapterBrowserView\n");
	  if (readingText == YES)
	    {
	      //readingText = NO;
	      transType = 2;
	    }
	  else
	    {
	      transType = 1; 
	    }
	}
      [transitionView transition:transType toView:view];
    }
}

- (void) applicationWillSuspend
{
  // Nothing yet.  Eventually we will write something,
  // probably to NSUserDefaults, which will allow us to pick up
  // where we left off.

  [defaults setFileBeingRead:[textView currentPath]];
  //[defaults setLastScrollPoint:[textView offset]];
  if (readingText)
    [defaults setTopViewIndex:TEXTVIEW];
  else
    [defaults setTopViewIndex:BROWSERVIEW];
  [defaults synchronize];

}

- (void) dealloc
{
  [booksItem release];
  [chaptersItem release];
  [bookItem release];
  [navBar release];
  [mainView release];
  [textView release];
  [browserView release];
  [defaults release];
  [super dealloc];
}

@end
