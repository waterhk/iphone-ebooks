#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UITextView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIKeyboard.h>
//#import <UIKit/UIWebView.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UINavigationItem.h>
#import "EBookView.h"
#import "FileBrowser.h"
#import "EBookNavItem.h"
#import "BooksDefaultsController.h"
#import "HideableNavBar.h"

@interface BooksApp : UIApplication {
	UIView      *mainView;
	HideableNavBar  *navBar, *bottomNavBar;
	UITransitionView *transitionView;
	EBookNavItem *booksItem, *chaptersItem, *bookItem;
        EBookView   *textView, *plainTextView, *HTMLTextView;
	FileBrowser *browserView;
	FileBrowser *chapterBrowserView;
	NSString    *path;
	NSError     *error;
	//UIViewTapInfo  *tapinfo;
	BOOL        bookHasChapters;
	BOOL        readingText;
	BOOL        doneLaunching;
	BOOL        transitionHasBeenCalled;
	BOOL        navbarsAreOn;
	float       size;
	BooksDefaultsController *defaults;
}

- (void)transitionToView:(id)view;
- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
@end
