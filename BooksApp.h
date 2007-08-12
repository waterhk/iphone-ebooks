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

@interface BooksApp : UIApplication {
	UIView      *mainView;
	UINavigationBar *navBar;
	UITransitionView *transitionView;
	EBookNavItem *booksItem, *chaptersItem, *bookItem;
        EBookView   *textView;
	FileBrowser *browserView;
	FileBrowser *chapterBrowserView;
	NSString    *path;
	NSError     *error;
	//UIViewTapInfo  *tapinfo;
	BOOL        bookHasChapters;
	BOOL        readingText;
	float       size;
}

- (void)transitionToView:(id)view;

@end
