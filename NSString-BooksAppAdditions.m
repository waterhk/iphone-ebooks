#import "NSString-BooksAppAdditions.h"

@implementation NSString (BooksAppAdditions)

- (BOOL)isReadableTextFilePath
{
  NSString *ext = [[self pathExtension] lowercaseString];
  return ([ext isEqualToString:@"txt"] || [ext isEqualToString:@"htm"] || [ext isEqualToString:@"html"]); 
}

- (NSString *)HTMLsubstringToIndex:(unsigned)index
{
  BOOL junk;
  return [self HTMLsubstringToIndex:index didLoadAll:&junk];
}

- (NSString *)HTMLsubstringToIndex:(unsigned)index
			didLoadAll:(BOOL *)didLoadAll
  // Returns an HTML string containing "index" number of PRINTING characters.
  // Does not add any closing tags to the HTML, just stops.
{
  unsigned len = [self length];
  unsigned numPrintingChars = 0;
  unsigned i;
  BOOL insideMarkup = NO;
  if (len < index)
    {
      *didLoadAll = YES;
      return [self copy];
    }
  for (i = 0; i < len; i++)
    {
      unichar c = [self characterAtIndex:i];
	if (c == (unichar)'<')
	  insideMarkup = YES;
	else if (c == (unichar)'>')
	  insideMarkup = NO;
	else
	  {
	    if ((!insideMarkup) && (c != (unichar)'\n') && (c != (unichar)'\t'))
	      {
		numPrintingChars++;
		if (numPrintingChars >= index)
		  {
		    *didLoadAll = NO;
		    return [self substringToIndex:i];
		  }
	      }
	  }
    }
  // If we get here, then we've exhausted the string.
  *didLoadAll = YES;
  return [self copy];
}

@end
