
#import <GraphicsServices/GraphicsServices.h>
#import "EBookView.h"

@implementation EBookView

- (id)initWithFrame:(struct CGRect)rect
{
  [super initWithFrame:rect];
  //  tapinfo = [[UIViewTapInfo alloc] initWithDelegate:self view:self];

  size = 16.0f;

  path = @"";

  [self setEditable:NO];
  
  [self setTextSize:size];
  [self setTextFont:@"TimesNewRoman"];

  [self setAllowsRubberBanding:YES];
  [self setBottomBufferHeight:0.0f];

  [self setScrollDecelerationFactor:0.99f];
  //  NSLog(@"scroll deceleration:%f\n", self->_scrollDecelerationFactor);
  [self setTapDelegate:self];
  return self;
}

- (void)loadBookWithPath:(NSString *)thePath
{
  path = [[thePath copy] retain];
  if ([[thePath pathExtension] isEqualToString:@"txt"])
    {
      [self setText:
	      [NSString 
		stringWithContentsOfFile:thePath
		encoding:NSUTF8StringEncoding
		error:NULL]];
    }
  else if ([[thePath pathExtension] isEqualToString:@"html"] ||
	   [[thePath pathExtension] isEqualToString:@"htm"])
    {
      [self setHTML:
	      [NSString 
		stringWithContentsOfFile:thePath
		encoding:NSUTF8StringEncoding
		error:NULL]];
    }
}

- (NSString *)currentPath;
{
  return path;
}
- (void)embiggenText
  // "A noble spirit embiggens the smallest man." -- Jebediah Springfield
{
  //FIXME: needs better scrolling support
  size += 2.0f;
  [self setTextSize:size];
  [self loadBookWithPath:path];
  [self setNeedsDisplay];
}

- (void)ensmallenText
  // "What the f--- does ensmallen mean?" -- Zach Brewster-Geisz
{
  size -= 2.0f;
  [self setTextSize:size];
  [self loadBookWithPath:path]; // This is horribly slow!  Is there a better way?
  [self setNeedsDisplay];
}
// None of these tap methods work yet.  They may never work.

- (void)handleDoubleTapEvent:(struct __GSEvent *)event
{
  [self embiggenText];
  //[super handleDoubleTapEvent:event];
}

- (void)handleSingleTapEvent:(struct __GSEvent *)event
{
  [self ensmallenText];
  //[super handleDoubleTapEvent:event];
}

- (void)mouseUp:(struct __GSEvent *)event
  // Why doesn't this work the way it should?
  // In Terminal.app, a single tap is properly noted.
  // But here, it always thinks we're scrolling for some reason.
{
  if ([self isScrolling])
    {
      // Ignore
    }
  else
    {
      [self embiggenText];
    }
  [super mouseUp:event];
}

- (void)dealloc
{
  //[tapinfo release];
  [path release];
  [super dealloc];
}

@end
