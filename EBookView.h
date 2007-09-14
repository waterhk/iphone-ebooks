#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITextTraitsClientProtocol.h>
//#import "UIKeyboardInputProtocol.h"
//#import <UIKit/UIWebView.h>
#import <UIKit/UIViewTapInfo.h>
//#import <UIKit/NSString-UIStringDrawing.h>
#import <UIKit/UIView-Geometry.h>

#import "BooksDefaultsController.h" //sigh...
#import "NSString-BooksAppAdditions.h"

@interface EBookView : UITextView
{
  //  UIViewTapInfo *tapinfo;
  NSString      *path;
  float         size;
  id            _heartbeatDelegate;
  struct CGRect lastVisibleRect;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void)loadBookWithPath:(NSString *)thePath;
- (void)loadBookWithPath:(NSString *)thePath numCharacters:(int)numChars didLoadAll:(BOOL *)didLoadAll;
- (void)loadBookWithPath:(NSString *)thePath numCharacters:(int)numChars;
- (NSString *)HTMLFileWithoutImages:(NSString *)thePath;
- (NSString *)currentPath;
- (void)embiggenText;
- (void)ensmallenText;
- (void)handleDoubleTapEvent:(struct __GSEvent *)event;
- (void)handleSingleTapEvent:(struct __GSEvent *)event;
- (void)setHeartbeatDelegate:(id)delegate;
- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (int)textSize;
- (void)setTextSize:(int)newSize;
- (NSString *)HTMLFromTextFile:(NSString *)file;
- (void)invertText:(BOOL)b;

@end
