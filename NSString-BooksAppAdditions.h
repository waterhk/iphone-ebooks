#import <Foundation/NSString.h>

@interface NSString (BooksAppAdditions)

- (NSString *)HTMLsubstringToIndex:(unsigned)index;
- (NSString *)HTMLsubstringToIndex:(unsigned)index didLoadAll:(BOOL *)didLoadAll;
@end
