#import <GraphicsServices/GraphicsServices.h>
#import "EBookView.h"

@implementation EBookView

- (id)initWithFrame:(struct CGRect)rect
{
  [super initWithFrame:rect];
  tapinfo = [[UIViewTapInfo alloc] initWithDelegate:self view:self];
  return self;
}

// None of these tap methods work yet.  They may never work.

- (void)handleDoubleTapEvent:(struct __GSEvent *)event
{
  NSLog(@"doubletap\n");
}

- (void)handleSingleTapEvent:(struct __GSEvent *)event
{
  NSLog(@"singletap\n");
}

- (void)dealloc
{
  [tapinfo release];
  [super dealloc];
}

@end
