// EBookImageView.m

#import "EBookImageView.h"

@implementation EBookImageView

-(EBookImageView *)initWithContentsOfFile:(NSString *)file
{
  struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
  self = [super initWithFrame:rect];
  [self setAllowsFourWayRubberBanding:YES];
  float components[4] = { 0.5, 0.5, 0.5, 1.0 };
  CGColorRef gray = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
  [self setBackgroundColor:gray];
  UIImage *img = [UIImage imageAtPath:file];
  //  struct CGSize size = [img size];
  CGImageRef imgRef = [img imageRef];
  unsigned int width = CGImageGetWidth(imgRef);
  unsigned int height = CGImageGetHeight(imgRef);
  if ((height != 0) && (width != 0))
    {
      float aspectRatio = (float)width / (float)height;
      
      if ((width < rect.size.width) && (height < (rect.size.height - 48)))
	{  // Let's be nice, and make the small images big!
	  if (height > width)
	    {
	      height = (unsigned int)(rect.size.height - 48);
	      width = (unsigned int)(height * aspectRatio);
	    }
	  else
	    {
	      width = (unsigned int)rect.size.width;
	      height = (unsigned int)(width / aspectRatio);
	    }
	}
      [self setContentSize:CGSizeMake(width,height + 48)];
      _imgView = [[UIImageView alloc] initWithImage:img];
      //Let's be super-nice and center the image if applicable!
      int x = 0;
      if (width < rect.size.width)
	x = (int)(rect.size.width - width) / 2;
      int y = 0;
      if (height < (rect.size.height - 48))
	y = (int)(rect.size.height - 48 - height) / 2;
      [_imgView setFrame:CGRectMake(x, y + 48, width, height)];
      [self addSubview:_imgView];
    }
  return self;

}

- (void)dealloc
{
  [_imgView release];
  [super dealloc];
}

@end
