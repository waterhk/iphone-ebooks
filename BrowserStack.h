// BrowserStack, for manipulating multiple FileBrowsers.
// Hides the actual browser objects from the rest of the app...
// or at least, that's what I'm going to try.

#ifndef EBOOK_BASE_PATH
#define EBOOK_BASE_PATH @"/var/root/Media/EBooks/"
#endif

#import <Foundation/Foundation.h>
#import "FileBrowser.h"

@interface BrowserStack : NSObject
{
  NSMutableArray *_stack;
  unsigned int _index;
  NSArray *_extensions;
  id _delegate;
}


-(BrowserStack *)initWithExtensions:(NSArray *)extensions delegate:(id)delegate;
-(NSString *)pop;
-(void)push:(NSString *)browserPath;
-(NSString *)peek;
-(NSArray *)arrayOfBrowserPaths;

@end
