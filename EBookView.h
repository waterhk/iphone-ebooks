#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITextTraitsClientProtocol.h>
//#import "UIKeyboardInputProtocol.h"
//#import <UIKit/UIWebView.h>
#import <UIKit/UIViewTapInfo.h>

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
- (NSString *)currentPath;
- (void)embiggenText;
- (void)ensmallenText;
- (void)handleDoubleTapEvent:(struct __GSEvent *)event;
- (void)handleSingleTapEvent:(struct __GSEvent *)event;
- (void)setHeartbeatDelegate:(id)delegate;
- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (int)textSize;
- (void)setTextSize:(int)newSize;
- (NSString *)HTMLFromTextFile:(NSString *)file;
- (void)invertText:(BOOL)b;

@end
