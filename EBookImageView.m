// EBookImageView.m

#import "EBookImageView.h"

@implementation EBookImageView

-(EBookImageView *)initWithContentsOfFile:(NSString *)file
{
  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0;
  self = [super initWithFrame:rect];
  [self setAllowsFourWayRubberBanding:YES];
  UIImage *img = [UIImage imageAtPath:file];
  //  struct CGSize size = [img size];
  CGImageRef imgRef = [img imageRef];
  unsigned int width = CGImageGetWidth(imgRef);
  unsigned int height = CGImageGetHeight(imgRef);
  [self setContentSize:CGSizeMake(width,height)];
  _imgView = [[UIImageView alloc] initWithImage:img];
  [self addSubview:_imgView];
  return self;

}

- (void)dealloc
{
  [_imgView release];
  [super dealloc];
}

@end
