// BrowserStack, for manipulating multiple FileBrowsers.

@interface BrowserStack : NSObject
{
  NSMutableArray *_stack;
  unsigned int _index;
  NSArray *_extensions;
}
-(BrowserStack *)initWithExtensions:(NSArray *)extensions;
-(FileBrowser *)pop;
-(void)push:(FileBrowser *)browser;
-(FileBrowser *)peek;
