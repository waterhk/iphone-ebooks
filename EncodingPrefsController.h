// EncodingPrefsController, for Books.app, by Zach Brewster-Geisz

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

#import "BooksDefaultsController.h"
#import "PreferencesController.h"

@interface EncodingPrefsController : NSObject
{
  UIPreferencesTable *encodingTable;
  BooksDefaultsController *defaults;
}

-(UITable *)table;
-(void)transitionToEncodingPrefs:(UITransitionView *)tView;
-(void)reloadData;
@end
