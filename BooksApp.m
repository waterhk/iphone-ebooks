#import "BooksApp.h"
//#import <UIKit/UIViewTapInfo.h>

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

    bookHasChapters = NO;
    readingText = NO;

    textView = [[EBookView alloc] 
        initWithFrame:
          CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    browserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    chapterBrowserView = [[FileBrowser alloc] initWithFrame:
		  CGRectMake(0, 0, rect.size.width, rect.size.height - 48.0f)];

    transitionView = [[UITransitionView alloc] initWithFrame:
       CGRectMake(rect.origin.x, 48.0f, rect.size.width, rect.size.height - 48.0f)];

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
	[navBar showButtonsWithLeftTitle:@"Books" rightTitle:nil leftBack:YES];
	[transitionView transition:1 toView:chapterBrowserView];
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
	[navBar showButtonsWithLeftTitle:leftTitle rightTitle:@"Bigger" leftBack:YES];
	[transitionView transition:1 toView:textView];
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
	  [navBar showButtonsWithLeftTitle:@"Books" rightTitle:nil leftBack:YES];
	  [transitionView transition:2 toView:chapterBrowserView];
	  readingText = NO;
	}
      else
	{
	  [transitionView transition:2 toView:browserView];
	  [navBar hideButtons];
	  bookHasChapters = NO;
	  readingText = NO;
	}
    }
  }
}

- (void) applicationWillSuspend
{
  // Nothing yet.  Eventually we will write something,
  // probably to NSUserDefaults, which will allow us to pick up
  // where we left off.
}

- (void) dealloc
{
  [navBar release];
  [mainView release];
  [textView release];
  [browserView release];
  [super dealloc];
}

@end
