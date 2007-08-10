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
    [textView setEditable:NO];

    size = 12.0f;

    [textView setTextSize:size];
    [textView setTextFont:@"TimesNewRoman"];

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
    [textView setAllowsRubberBanding:YES];
    [textView setBottomBufferHeight:0.0f];
    //[textView setDelegate:self];
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
	[textView setHTML:
		    [NSMutableString 
		      stringWithContentsOfFile:file
		      encoding:NSMacOSRomanStringEncoding
		      error:&error]];

	if (bookHasChapters)
	  leftTitle = @"Chapters";
	else
	  leftTitle = @"Books";
	[navBar showButtonsWithLeftTitle:leftTitle rightTitle:@"Bigger" leftBack:YES];
	[transitionView transition:1 toView:textView];
	readingText = YES;
      }
}


/*  FIXME--what I want is to dynamically resize and reflow the text,
    so call it, say, a double-tap to make text bigger, and a single-tap
    to make it smaller.  But how?

- (void)mouseUp:(struct __GSEvent *)fp8
{
    float size = [textView textSize];

    if (GSEventGetClickCount(fp8) == 2)
      {
	[textView setTextSize:(size + 2.0f)];
	[textView setNeedsDisplay];
      }
    else if (GSEventGetClickCount(fp8) == 1)
      {
	[textView setTextSize:(size - 2.0f)];
	[textView setNeedsDisplay];
      }
}

*/
- (void)navigationBar:(UINavigationBar *)thebar buttonClicked:(int)button {
  switch (button) {
  case 0:// right
    if (readingText)
      {
	size += 2.0f;
	[textView setTextSize:size];
	[textView setNeedsDisplay];
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
  /*   [[textView text]
	writeToFile: path 
	atomically: NO 
	encoding: NSMacOSRomanStringEncoding
	error: &error]; */
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
