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
  NSStringEncoding encoding;
  NSString *originalText;
  path = [[thePath copy] retain];
  if ([[[thePath pathExtension] lowercaseString] isEqualToString:@"txt"])
    {
      [self setHTML: [self HTMLFromTextFile:thePath]];
    }
  else if ([[[thePath pathExtension] lowercaseString] isEqualToString:@"html"] ||
	   [[[thePath pathExtension] lowercaseString] isEqualToString:@"htm"])
    {
      originalText = [NSString 
		       stringWithContentsOfFile:thePath
		       usedEncoding:&encoding
		       error:NULL];
      if (nil == originalText)
	{
	  originalText = [NSString stringWithContentsOfFile:thePath
				   encoding: NSUTF8StringEncoding
				   error:NULL];
	}
      if (nil == originalText)
	{
	  originalText = [NSString stringWithContentsOfFile:thePath
				   encoding: NSISOLatin1StringEncoding
				   error:NULL];
	}
      if (nil == originalText)
	{
	  originalText = [NSString stringWithContentsOfFile:thePath
				   encoding: NSMacOSRomanStringEncoding
				   error:NULL];
	}
      if (nil == originalText)
	{
	  originalText = [NSString stringWithContentsOfFile:thePath
				   encoding: NSASCIIStringEncoding
				   error:NULL];
	}
      [self setHTML:originalText];
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
      float scrollFactor = (size + 3)/size;  
      size += 2.0f;
      middleRect *= scrollFactor;
      oldRect.origin.y = middleRect - (oldRect.size.height / 2);
      NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
      [self setTextSize:size];
      [self loadBookWithPath:path];
      [self scrollPointVisibleAtTopLeft:oldRect.origin animated:YES];
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
      float scrollFactor = (size - 3)/size;
      size -= 2.0f;
      middleRect *= scrollFactor;
      oldRect.origin.y = middleRect - (oldRect.size.height / 2);
      [self setTextSize:size];
      [self loadBookWithPath:path]; // This is horribly slow!  Is there a better way?
      [self scrollPointVisibleAtTopLeft:oldRect.origin animated:YES];
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
  /*************
   * NOTE: THE GSEVENTGETLOCATIONINWINDOW INVOCATION
   * WILL NOT COMPILE UNLESS YOU HAVE PATCHED GRAPHICSSERVICES.H TO ALLOW IT!
  *****************/

  struct CGRect clicked = GSEventGetLocationInWindow(event);
  struct CGRect newRect = [self visibleRect];
  struct CGRect topTapRect = CGRectMake(0, 0, 320, 48);
  struct CGRect contentRect = [UIHardware fullScreenApplicationContentRect];
  struct CGRect botTapRect = CGRectMake(0, contentRect.size.height - 48, contentRect.size.width, 48);
  if ([self isScrolling])
    {
      if (CGRectContainsPoint(topTapRect, clicked.origin))
	{
	  //scroll back one screen...
	  [self scrollByDelta:CGSizeMake(0, -1*(contentRect.size.height - size)) 
		animated:YES];
	  [self hideNavbars];
	}
      else if (CGRectContainsPoint(botTapRect,clicked.origin))
	{
	  //scroll forward one screen...
	  [self scrollByDelta:CGSizeMake(0, contentRect.size.height - size)
		animated:YES];
	  [self hideNavbars];
	}
      else if (CGRectEqualToRect(lastVisibleRect, newRect))
	{  // If the old rect equals the new, then we must not be scrolling
	  [self toggleNavbars];
	}
      else
	{ //we are, in fact, scrolling
	  [self hideNavbars];
	}
    }

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

- (NSString *)HTMLFromTextFile:(NSString *)file
{
  NSStringEncoding encoding;
  NSString *header = @"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 3.2//EN\">\n<html>\n\n<head>\n<title></title>\n</head>\n\n<body>\n";
  NSMutableString *originalText = [[NSMutableString alloc] 
				    initWithContentsOfFile:file
				    usedEncoding:&encoding
				    error:NULL];
  NSString *outputHTML;

  if (nil == originalText)
    {
      originalText = [[NSMutableString alloc]
		       initWithContentsOfFile:file
		       encoding:NSUTF8StringEncoding error:NULL];
    }
  if (nil == originalText)
    {
      originalText = [[NSMutableString alloc]
		       initWithContentsOfFile:file
		       encoding:NSISOLatin1StringEncoding error:NULL];
    }
  if (nil == originalText)
    {
      originalText = [[NSMutableString alloc]
		       initWithContentsOfFile:file
		       encoding:NSMacOSRomanStringEncoding error:NULL];
    }
  if (nil == originalText)
    {
      originalText = [[NSMutableString alloc]
		       initWithContentsOfFile:file
		       encoding:NSASCIIStringEncoding error:NULL];
    }
  if (nil == originalText)
    return nil;

  NSRange fullRange = NSMakeRange(0, [originalText length]);

  unsigned int i,j;
  j=0;
  i = [originalText replaceOccurrencesOfString:@"&" withString:@"&amp;"
		    options:NSLiteralSearch range:fullRange];
  NSLog(@"replaced %d &s\n", i);
  j += i;
  fullRange = NSMakeRange(0, [originalText length]);
  i = [originalText replaceOccurrencesOfString:@"<" withString:@"&lt;"
		    options:NSLiteralSearch range:fullRange];
  NSLog(@"replaced %d <s\n", i);
  j += i;
  fullRange = NSMakeRange(0, [originalText length]);
  i = [originalText replaceOccurrencesOfString:@">" withString:@"&gt;"
		    options:NSLiteralSearch range:fullRange];
  NSLog(@"replaced %d >s\n", i);
  j += i;
  fullRange = NSMakeRange(0, [originalText length]);
  // Argh, bloody MS line breaks!  Change them to UNIX, then...
  i = [originalText replaceOccurrencesOfString:@"\r\n" withString:@"\n"
		    options:NSLiteralSearch range:fullRange];
  NSLog(@"replaced %d carriage return/newlines\n", i);
  j += i;
  fullRange = NSMakeRange(0, [originalText length]);
  // Change UNIX newlines to <br> tags.
  i = [originalText replaceOccurrencesOfString:@"\n" withString:@"<br />\n"
		    options:NSLiteralSearch range:fullRange];
  NSLog(@"replaced %d newlines\n", i);
  j += i;
  fullRange = NSMakeRange(0, [originalText length]);
  // And just in case someone has a Classic MacOS textfile...
  i = [originalText replaceOccurrencesOfString:@"\r" withString:@"<br />\n"
		    options:NSLiteralSearch range:fullRange];
  NSLog(@"replaced %d carriage returns\n", i);
  j += i;

  NSLog(@"Replaced %d characters in textfile %@.\n", j, file);
  outputHTML = [[NSString alloc] initWithFormat:@"%@%@\n</body>\n</html\n", header, originalText];
  [originalText release];
  return [outputHTML autorelease];
}


- (void)dealloc
{
  //[tapinfo release];
  [path release];
  [super dealloc];
}

@end
