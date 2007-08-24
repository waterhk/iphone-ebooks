// PreferencesView, for Books by Chris Born

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIAlertSheet.h>

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
	
	UISegmentedControl 			*fontChoiceControl;
	UIPreferencesTextTableCell 	*fontChoicePreferenceCell;
    UIPreferencesTextTableCell 	*fontSizePreferenceCell;
	UIPreferencesControlTableCell *invertPreferenceCell;
	UIPreferencesControlTableCell *autoHidePreferenceCell;
	UIPreferencesControlTableCell *showToolbarPreferenceCell;
	UIPreferencesControlTableCell *flippedToolbarPreferenceCell;
	
	struct CGRect contentRect;
}

- (id)initWithAppController:(BooksApp *)appController;
- (UIPreferencesTable *)createPrefsPane;
- (void)showPreferences;
- (void)hidePreferences;
- (void)createPreferenceCells;
- (void)testAlert;

// Hacks until font chooser is sorted out
#define TIMES 0
#define VERDANA 1
#define GEORGIA 2

- (int)currentFontIndex;
- (NSString *)fontNameForIndex:(int)index;

@end