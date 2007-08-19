#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import "EBookView.h"
#import "BooksDefaultsController.h"

@interface NSObject (HeartbeatDelegate)

- (void)heartbeatCallback:(id)ignored;

@end


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

  [self scrollToMakeCaretVisible:NO];

  [self setScrollDecelerationFactor:0.99f];
  //  NSLog(@"scroll deceleration:%f\n", self->_scrollDecelerationFactor);
  [self setTapDelegate:self];

  lastVisibleRect = [self visibleRect];
  return self;
}

- (void)heartbeatCallback:(id)unused
{
  if (_heartbeatDelegate != nil) {
    if ([_heartbeatDelegate respondsToSelector:@selector(heartbeatCallback:)]) {
      [_heartbeatDelegate heartbeatCallback:self];
    } else {
      [NSException raise:NSInternalInconsistencyException
		   format:@"Delegate doesn't respond to selector"];
    }
  }
}

- (void)setHeartbeatDelegate:(id)delegate
{
  _heartbeatDelegate = delegate;
  [self startHeartbeat:@selector(heartbeatCallback:) inRunLoopMode:nil];
}

- (void)hideNavbars
{
  if (_heartbeatDelegate != nil) {
    if ([_heartbeatDelegate respondsToSelector:@selector(hideNavbars)]) {
      [_heartbeatDelegate hideNavbars];
    } else {
      [NSException raise:NSInternalInconsistencyException
		   format:@"Delegate doesn't respond to selector"];
    }
  }
}

- (void)toggleNavbars
{
  if (_heartbeatDelegate != nil) {
    if ([_heartbeatDelegate respondsToSelector:@selector(toggleNavbars)]) {
      [_heartbeatDelegate toggleNavbars];
    } else {
      [NSException raise:NSInternalInconsistencyException
		   format:@"Delegate doesn't respond to selector"];
    }
  }
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
  if (size < 36.0f)
    {
      struct CGRect oldRect = [self visibleRect];
      NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
      float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
      float scrollFactor = middleRect / (size*2.2f);  // Number of lines down
      size += 2.0f;
      middleRect = scrollFactor * (size*2.2f);
      oldRect.origin.y = middleRect - (oldRect.size.height / 2);
      NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
      [self setTextSize:size];
      [self loadBookWithPath:path];
      [self scrollPointVisibleAtTopLeft:oldRect.origin];
      [self setNeedsDisplay];
    }
}

- (void)ensmallenText
  // "What the f--- does ensmallen mean?" -- Zach Brewster-Geisz
{
  if (size > 10.0f)
    {
      struct CGRect oldRect = [self visibleRect];
      float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
      float scrollFactor = middleRect / (size*2.2f);  // Number of lines down
      size -= 2.0f;
      middleRect = scrollFactor * (size*2.2f);
      oldRect.origin.y = middleRect - (oldRect.size.height / 2);
      [self setTextSize:size];
      [self loadBookWithPath:path]; // This is horribly slow!  Is there a better way?
      [self scrollPointVisibleAtTopLeft:oldRect.origin];
      [self setNeedsDisplay];
    }
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
  // 8/14/07 --These events may work now, but we have an insertion point.
  // ARGH.
{
  struct CGRect newRect = [self visibleRect];
  if ([self isScrolling])
    {
      if (CGRectEqualToRect(lastVisibleRect, newRect))
	{  // If the old rect equals the new, then we must not be scrolling
	  [self toggleNavbars];
	}
      else
	{ //we are, in fact, scrolling
	  [self hideNavbars];
	}
    }
  /*
  else //two-finger tap
    {
      [self ensmallenText];
    }
  */
  lastVisibleRect = [self visibleRect];
  [super mouseUp:event];
}

- (int)textSize
  // This method is needed because the toolchain doesn't
  // currently handle floating-point return values in an
  // ARM-friendly way.
{
  return (int)size;
}

- (void)setTextSize:(int)newSize
{
  size = (float)newSize;
  [super setTextSize:size];
}

- (void)dealloc
{
  //[tapinfo release];
  [path release];
  [super dealloc];
}

@end
