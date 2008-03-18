// EBookImageView.m, for Books.app by Zachary Brewster-Geisz
/*
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; version 2
 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 */

#import "EBookImageView.h"
#import "BooksDefaultsController.h"

@implementation EBookImageView
/**
 * Init with image to show and frame to draw in.
 */
- (EBookImageView *)initWithContentsOfFile:(NSString *)file withFrame:(struct CGRect)p_frame scaleAspect:(BOOL)p_aspect{
  struct CGSize size = p_frame.size;
  
  if(self = [super initWithFrame:p_frame]) {
    [self setAllowsFourWayRubberBanding:YES];
    
    float components[4] = { 0.0, 0.0, 0.0, 0.0 };
    CGColorRef transparent = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
    [self setBackgroundColor:transparent];
    
    [self showImage:file inFrame:p_frame scaleAspect:p_aspect];
  }
  return self;
}

/**
 * Set the image and frame.
 */
- (void)showImage:(NSString*)p_path inFrame:(struct CGRect)p_frame scaleAspect:(BOOL)p_aspect {
  struct CGSize size = p_frame.size;
  
  UIImage *img = [UIImage imageAtPath:p_path];
  CGImageRef imgRef = [img imageRef];
  unsigned int width = CGImageGetWidth(imgRef);
  unsigned int height = CGImageGetHeight(imgRef);
  
  if((height != 0) && (width != 0)) {
    _imgView = [[UIImageView alloc] initWithImage:img];
    
    if(p_aspect) {
      float aspectRatio = (float)width / (float)height;
      if(aspectRatio < (size.width/size.height)) {
        height = (unsigned int)size.height;
        width = (unsigned int)(height * aspectRatio);
      } else {
        width = (unsigned int)size.width;
        height = (unsigned int)(width / aspectRatio);
      }
      
      [self setContentSize:CGSizeMake(width, height)];
      
      //Let's be super-nice and center the image if applicable!
      int x = 0;
      if (width < p_frame.size.width) {
        x = (int)(p_frame.size.width - width) / 2;
      }
      
      int y = 0;
      if (height < (p_frame.size.height)) {
        y = (int)(p_frame.size.height - height) / 2;
      }
      
      [_imgView setFrame:CGRectMake(x, y, width, height)];
    } else {
      [self setContentSize:p_frame.size];
      [_imgView setFrame:p_frame];
    }
    [self addSubview:_imgView];
  }
}

/**
 * Just show an image using the current frame.
 */
- (void)showImage:(NSString*)p_path {
  [self showImage:p_path inFrame:[self frame] scaleAspect:YES];
}

/**
 * Cleanup.
 */
- (void)dealloc {
  [_imgView release];
  [super dealloc];
}

/**
 * Search through common file extensions to find a cover.* image for the given book.
 */
+(NSString *)coverArtForBookPath:(NSString *)path {
  BOOL isDir;
  NSFileManager *defaultM = [NSFileManager defaultManager];
  BOOL fileExists = [defaultM fileExistsAtPath:path isDirectory:&isDir];
  NSString *basePath;
  if (isDir) {
    basePath = path;
  } else {
    basePath = [path stringByDeletingLastPathComponent];
  }
  
  if ([defaultM fileExistsAtPath:[basePath stringByAppendingPathComponent:@"cover.jpg"]]) {
    return [basePath stringByAppendingPathComponent:@"cover.jpg"];
  }
  
  if ([defaultM fileExistsAtPath:[basePath stringByAppendingPathComponent:@"cover.png"]]) {
    return [basePath stringByAppendingPathComponent:@"cover.png"];
  }
  
  if ([defaultM fileExistsAtPath:[basePath stringByAppendingPathComponent:@"cover.gif"]]) {
    return [basePath stringByAppendingPathComponent:@"cover.gif"];
  }
  
  return nil;
}

@end
