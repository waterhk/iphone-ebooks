#import <GraphicsServices/GraphicsServices.h>
#import "EBookView.h"

@implementation EBookView

- (id)initWithFrame:(struct CGRect)rect
{
  [super initWithFrame:rect];
  tapinfo = [[UIViewTapInfo alloc] initWithDelegate:self view:self];

  size = 16.0f;

  path = @"";

  [self setEditable:NO];
  
  [self setTextSize:size];
  [self setTextFont:@"TimesNewRoman"];

  [self setAllowsRubberBanding:YES];
  [self setBottomBufferHeight:0.0f];

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

- (void)embiggenText
  // "A noble spirit embiggens the smallest man." -- Jebediah Springfield
{
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
  [self loadBookWithPath:path];
  [self setNeedsDisplay];
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
  [path release];
  [super dealloc];
}

@end
