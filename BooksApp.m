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
    UIWindow *window;
    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;

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

    browserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    chapterBrowserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    transitionView = [[UITransitionView alloc] initWithFrame:
       CGRectMake(rect.origin.x, 48.0f, rect.size.width, rect.size.height - 48.0f)];

    booksItem = [[EBookNavItem alloc] initWithTitle:@"Books" view:browserView];
    chaptersItem = [[EBookNavItem alloc] initWithTitle:@"Chapters" view:chapterBrowserView];
    bookItem = [[EBookNavItem alloc] initWithTitle:@"" view:textView];

    [browserView setExtensions:[NSArray arrayWithObjects:@"txt", @"html", @"htm", nil]];
    [chapterBrowserView setExtensions:[NSArray arrayWithObjects:@"txt", @"html", @"htm", nil]];


    [booksItem setDelegate:self];
    [chaptersItem setDelegate:self];
    [bookItem setDelegate:self];

    [navBar pushNavigationItem:booksItem];

    bookHasChapters = NO;
    readingText = NO;


    path = @"/var/root/Media/EBooks/";

    [browserView setPath:path];
    [browserView setDelegate:self];
    [chapterBrowserView setDelegate:self];


    [window setContentView: mainView];
    [mainView addSubview:navBar];
    [mainView addSubview:transitionView];

    [transitionView transition:1 toView:browserView];
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
	[textView loadBookWithPath:file];

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
	  transType = 2;
	}
      else
	{
	  transType = 1; 
	}
    }
  [transitionView transition:transType toView:view];
}

- (void) applicationWillSuspend
{
  // Nothing yet.  Eventually we will write something,
  // probably to NSUserDefaults, which will allow us to pick up
  // where we left off.
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
  [super dealloc];
}

@end
