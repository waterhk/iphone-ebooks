// HTMLFixer.h, for Books.app by Zachary Brewster-Geisz

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "NSString-BooksAppAdditions.h"
#import "BooksDefaultsController.h"

@class AGRegex;

@interface HTMLFixer : NSObject {
  
}

+ (NSString *)fixedImageTagForString:(NSString *)str basePath:(NSString *)path returnImageHeight:(int *)height;
+ (void)fixedHTMLStringForString:(NSMutableString *)theOldHTML filePath:(NSString *)thePath textSize:(int)size;
+ (void)replaceRegex:(AGRegex*)p_regex withString:(NSString*)p_repl inMutableString:(NSMutableString*)p_mut;
@end
