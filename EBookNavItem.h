/// EBookNavItem
/// by Zachary Brewster-Geisz for Books.app
/// (c) 2007

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UINavigationItem.h>


@interface EBookNavItem : UINavigationItem
{
  UIView *theView;
  id theDelegate;
}

- (EBookNavItem *)initWithTitle:(id)title view:(id)view;
- (void)setDelegate:(id)delegate;
@end
