// BooksApp, (c) 2007 by Zachary Brewster-Geisz

/*

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
#import <UIKit/UIProgressIndicator.h>
#import <UIKit/UISliderControl.h>
#import <UIKit/UIAlphaAnimation.h>
#import "EBookView.h"
#import "EBookImageView.h"
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "HideableNavBar.h"
#import "common.h"

@class PreferencesController;

@interface BooksApp : UIApplication {
	UIWindow 	*window;
	UIView      *mainView;
	HideableNavBar  *navBar, *bottomNavBar;
	UISliderControl *scrollerSlider;
	UITransitionView *transitionView;
        EBookView   *textView;
	EBookImageView *imageView;
	PreferencesController *prefController;
	NSString    *path;
	NSError     *error;
	BOOL        bookHasChapters;
	BOOL        readingText;
	BOOL        doneLaunching;
	BOOL        transitionHasBeenCalled;
	BOOL        textViewNeedsFullText;
	BOOL        navbarsAreOn;
	BOOL		textInverted;
	BOOL        imageSplashed;
	BOOL        rotate90;
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
	
	UIProgressIndicator *progressIndicator;

	UIImage *buttonImg;
	NSString *imgPath;

	UIAnimator *animator;
	UIAlphaAnimation *alpha;
}
- (void)textViewDidGoAway:(id)sender;
- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file;

- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)showSlider;
- (void)hideSlider;
- (void)handleSlider:(id)sender;
- (void)embiggenText:(UINavBarButton *)button;
- (void)ensmallenText:(UINavBarButton *)button;
- (void)invertText:(UINavBarButton *)button;
- (void)setTextInverted:(BOOL)b;
- (void)setupNavbar;
- (void)setupToolbar;
- (void)updateToolbar:(NSNotification *)notification;
- (UINavBarButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped;
- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped;
- (void)textViewDidGoAway:(id)sender;
- (void)showPrefs:(UINavBarButton *)button;
- (UIWindow *)appsMainWindow;
- (void)refreshTextViewFromDefaults;
- (void)refreshTextViewFromDefaultsToolbarsOnly:(BOOL)toolbarsOnly;
- (void)toggleStatusBarColor;
- (NSString *)currentBrowserPath;
- (void)cleanUpBeforeQuit;
@end
