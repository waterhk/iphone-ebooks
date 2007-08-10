#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITextTraitsClientProtocol.h>
//#import <UIKit/UIWebView.h>
#import <UIKit/UIViewTapInfo.h>

@interface EBookView : UITextView
{
  UIViewTapInfo *tapinfo;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void)handleDoubleTapEvent:(struct __GSEvent *)event;
- (void)handleSingleTapEvent:(struct __GSEvent *)event;

@end
