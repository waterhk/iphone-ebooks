/// EBookNavItem

#import "EBookNavItem.h"

@implementation EBookNavItem
- (EBookNavItem *)initWithTitle:(id)title view:(id)view
{
  [super initWithTitle:title];
  theView = [view retain];
  theDelegate = nil;
  return self;
}

- (void)setDelegate:(id)delegate;
{
  theDelegate = [delegate retain];
}

- (void) willBecomeTopInNavigationBar:(id)theBar navigationBarState:(int)state
{
  NSLog(@"willBecomeTop\n");
  if ([theDelegate respondsToSelector:@selector(transitionForwardToView:)])
    {
      [theDelegate transitionForwardToView:theView];
    }
  [super willBecomeTopInNavigationBar:theBar navigationBarState:state];
}
/*
- (void)willResignTopInNavigationBar:(id)theBar navigationBarState:(int)state
{
  NSLog(@"willResignTop");
  if ([theDelegate respondsToSelector:@selector(transitionBackwardToView:)])
    {
      [theDelegate transitionBackwardToView:theView];
    }
  [super willResignTopInNavigationBar:theBar navigationState:state];
}
*/
- (void)dealloc
{
  [theView release];
  [theDelegate release];
  [super dealloc];
}

@end
