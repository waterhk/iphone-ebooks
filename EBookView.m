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

  [self setScrollDecelerationFactor:0.99f];
  //  NSLog(@"scroll deceleration:%f\n", self->_scrollDecelerationFactor);
  [self setTapDelegate:self];
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
  struct CGRect oldRect = [self visibleTextRect];
  //FIXME: needs better scrolling support
  if (size < 36.0f)
    size += 2.0f;
  [self setTextSize:size];
  [self loadBookWithPath:path];
  [self scrollRectToVisible:oldRect];
  [self setNeedsDisplay];
}

- (void)ensmallenText
  // "What the f--- does ensmallen mean?" -- Zach Brewster-Geisz
{
  if (size > 10.0f)
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
  // 8/14/07 --These events may work now, but we have an insertion point.
  // ARGH.
{
  if ([self isScrolling])
    {
      //      struct CGRect rect = [self visibleRect];
      //[[textView defaultsController] setLastScrollPoint:(unsigned int)visibleRect.origin.y];

      // Ignore
    }
  else
    {
      int count = GSEventGetClickCount(event);  // nope, doesn't work
      switch (count)
	{
	case 1:
	  [self embiggenText];
	  break;
	case 2:
	  [self ensmallenText];
	  break;
	default:
	  break;
	}
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
