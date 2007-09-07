// PreferencesView, for Books by Chris Born

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UIPopup.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIAnimator.h>
#import <UIKit/UIAnimation.h>
#import <UIKit/UITransformAnimation.h>
#import <UIKit/UIViewHeartbeat.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIPickerView.h>
#import <UIKit/UIPickerTableCell.h>
#import <UIKit/UITextView.h> // For testing: remove

#import "BooksApp.h"
#import "BooksDefaultsController.h"


@interface PreferencesController : NSObject {
	
	UINavigationBar				*navBar;
	UITextView					*textView;
	BooksDefaultsController		*defaults;
	BooksApp					*controller;
	UIAlertSheet				*alertSheet;
	UIPreferencesTable			*preferencesTable;
	
	UIView						*appView;
	UIView                      *preferencesView;
	UISegmentedControl 			*fontChoiceControl;
	UISegmentedControl 			*flippedToolbarControl;
	UIPreferencesTextTableCell 	*fontChoicePreferenceCell;
    UIPreferencesTextTableCell 	*fontSizePreferenceCell;
	UIPreferencesControlTableCell *invertPreferenceCell;
	UIPreferencesControlTableCell *showToolbarPreferenceCell;
	UIPreferencesControlTableCell *showNavbarPreferenceCell;
	UIPreferencesControlTableCell *chapterButtonsPreferenceCell;
	UIPreferencesControlTableCell *pageButtonsPreferenceCell;	
	UIPreferencesControlTableCell *flippedToolbarPreferenceCell;
	UIPreferencesControlTableCell *defaultEncodingPreferenceCell;
	UIPreferencesControlTableCell *markCurrentBookAsNewCell;
	UIPreferencesControlTableCell *markAllBooksAsNewCell;
	
	struct CGRect contentRect;

	BOOL needsInAnimation, needsOutAnimation; // here's hoping.
	UIAnimator *animator;
	UITransformAnimation *translate;
}

- (id)initWithAppController:(BooksApp *)appController;
- (void)showPreferences;
- (void)hidePreferences;
- (void)createPreferenceCells;
- (void)tableRowSelected:(NSNotification *)notification;
- (void)makeEncodingPrefsPane;

#define PREFS_NEEDS_ANIMATE @"prefsNeedsAnimateNotification"

- (void)checkForAnimation:(id)unused;

#define RIGHTHANDED 0
#define LEFTHANDED 1

#define GEORGIA 0
#define HELVETICA 1
#define TIMES 2

- (int)currentFontIndex;
- (NSString *)fontNameForIndex:(int)index;

@end
