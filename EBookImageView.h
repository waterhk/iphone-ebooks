// EBookImageView, for Books.app by Zach Brewster-Geisz


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIView-Rendering.h>
#import <CoreGraphics/CoreGraphics.h>

@interface EBookImageView : UIScroller

{
  UIImageView *_imgView;
}

-(EBookImageView *)initWithContentsOfFile:(NSString *)file;

@end
