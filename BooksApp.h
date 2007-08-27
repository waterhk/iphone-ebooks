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
#import <UIKit/UINavBarButton.h>
#import <UIKit/UIFontChooser.h>
#import "EBookView.h"
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "HideableNavBar.h"
#import "common.h"

@class PreferencesController;

@interface BooksApp : UIApplication {
	UIWindow 	*window;
	UIView      *mainView;
	HideableNavBar  *navBar, *bottomNavBar;
	UITransitionView *transitionView;
	//EBookNavItem *booksItem, *chaptersItem, *bookItem;
        EBookView   *textView;  /* *plainTextView, *HTMLTextView;*/
	//FileBrowser *browserView;
	//FileBrowser *chapterBrowserView;
	NSString    *path;
	NSError     *error;
	//UIViewTapInfo  *tapinfo;
	BOOL        bookHasChapters;
	BOOL        readingText;
	BOOL        doneLaunching;
	BOOL        transitionHasBeenCalled;
	BOOL        navbarsAreOn;
	BOOL		textInverted;
	float       size;
	BooksDefaultsController *defaults;
	UINavBarButton *minusButton;
	UINavBarButton *plusButton;
	UINavBarButton *invertButton;
	UINavBarButton *prefsButton;
	UINavBarButton *downButton;
	UINavBarButton *upButton;
	UINavBarButton *rightButton;
	UINavBarButton *leftButton;
	
	UIImage *buttonImg;
	NSString *imgPath;
}

//- (void)transitionToView:(id)view;
- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)embiggenText:(UINavBarButton *)button;
- (void)ensmallenText:(UINavBarButton *)button;
- (void)invertText:(UINavBarButton *)button;
- (void)setTextInverted:(BOOL)b;
- (void)setupNavbar;
- (void)setupToolbar;
- (void)updateToolbar:(NSNotification *)notification;
- (UINavBarButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector;
- (UIImage *)navBarImage:(NSString *)name;
- (void)textViewDidGoAway:(id)sender;
- (void)showPrefs:(UINavBarButton *)button;
- (UIWindow *)appsMainWindow;
- (void)refreshTextViewFromDefaults;
@end