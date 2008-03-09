// HTMLFixer.m, for Books.app by Zachary Brewster-Geisz
/* Most of this file is now obsolete.  Don't get excited if warnings
 from some of the methods appear on compile.  They're probably unused.
 */

#include "HTMLFixer.h"
#import "AGRegex/AGRegex.h"

/*
 * All of these regex's are thread safe, etc.  Regex patterns should be immutable always.
 * We'll alloc a boat load of them here once and use them whenever they're needed below.
 */

// Image tag fixers
AGRegex *SRC_REGEX;
AGRegex *IMGTAG_REGEX;

// Open table elements
AGRegex *TABLE_REGEX;
AGRegex *TR_REGEX;
AGRegex *TD_REGEX;
AGRegex *TH_REGEX;

// Close table elements
AGRegex *TABLECL_REGEX;
AGRegex *TRCL_REGEX;
AGRegex *TDCL_REGEX;
AGRegex *THCL_REGEX;

// Assorted problematic block elements
AGRegex *STYLE_REGEX;

@implementation HTMLFixer

/**
 * Setup all the regex's we need.
 */
+ (void)initialize {
  // Image tag fixers
  SRC_REGEX = [[AGRegex alloc] initWithPattern:@"src=[\"']([^\\\"]+)[\"']" options:AGRegexCaseInsensitive];
  IMGTAG_REGEX = [[AGRegex alloc] initWithPattern:@"<img[^>]+>" options:AGRegexCaseInsensitive];
  
  // Open table elements
  TABLE_REGEX = [[AGRegex alloc] initWithPattern:@"<table[^>]+>" options:AGRegexCaseInsensitive];
  TR_REGEX = [[AGRegex alloc] initWithPattern:@"<tr[^>]+>" options:AGRegexCaseInsensitive];
  TD_REGEX = [[AGRegex alloc] initWithPattern:@"<td[^>]+>" options:AGRegexCaseInsensitive];
  TH_REGEX = [[AGRegex alloc] initWithPattern:@"<th[^>]+>" options:AGRegexCaseInsensitive];
  
  // Close table elements
  TABLECL_REGEX = [[AGRegex alloc] initWithPattern:@"</table[^>]+>" options:AGRegexCaseInsensitive];
  TRCL_REGEX = [[AGRegex alloc] initWithPattern:@"</tr[^>]+>" options:AGRegexCaseInsensitive];
  TDCL_REGEX = [[AGRegex alloc] initWithPattern:@"</td[^>]+>" options:AGRegexCaseInsensitive];
  THCL_REGEX = [[AGRegex alloc] initWithPattern:@"</th[^>]+>" options:AGRegexCaseInsensitive];
  
  // Assorted problematic block elements
  STYLE_REGEX = [[AGRegex alloc] initWithPattern:@"<(?:style|script|object|embed)[^<]+</(?:style|script|object|embed)>" 
                                                  options:AGRegexCaseInsensitive]; 
}

/**
 * Returns an image tag for which the image has been shrunk to 300 pixels wide.
 * Changes the local file URL to an absolute URL since that's what the UITextView seems to like.
 * Does nothing if the image is already under 300 px wide.
 * Assumes a local URL as the "src" element.
 */
+(NSString *)fixedImageTagForString:(NSString *)aStr basePath:(NSString *)path returnImageHeight:(int *)returnHeight {
  // Build the final image tag from these:
  NSString *srcString = nil;
  unsigned int width = 300;
  unsigned int height = 0;
  
  // Use a regex to find the src attribute.
  AGRegexMatch *srcMatch = [SRC_REGEX findInString:aStr];
  if(srcMatch == nil || [srcMatch count] != 2) {
    // We didn't find a match, or we found MULTIPLE matches.  Just bail...
    GSLog(@"No src regex match found in %@", aStr);
    return @"";
  } else {
    srcString = [srcMatch groupAtIndex:1];
    if([srcString length] == 0) {
      GSLog(@"No src regex match found in %@", aStr);
      return @"";
    }
  }
  
  // Clean up the URL a bunch.
  //FIXME:  Should I worry about encodings?
  NSString *noPercentString = [srcString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
  NSString *imgPath = [[path stringByAppendingPathComponent:noPercentString] stringByStandardizingPath];
  NSURL *pathURL = [NSURL fileURLWithPath:imgPath];
  NSString *absoluteURLString = [pathURL absoluteString];
  
  GSLog(@"absoluteURLString: %@", absoluteURLString);
  
  NSString *finalImgTag;
  
  // Try to read the URL off the filesystem to get its height and width.
  UIImage *img = [UIImage imageAtPath:imgPath];
  if (nil != img) {
    CGImageRef imgRef = [img imageRef];
    height = CGImageGetHeight(imgRef);
    width = CGImageGetWidth(imgRef);
    //NSLog(@"image's width: %d height: %d", width, height);
    if (width <= 300) {
      *returnHeight = (int)height;
    } else {
      float aspectRatio = (float)height / (float)width;
      width = 300;
      height = (unsigned int)(300.0 * aspectRatio);
      *returnHeight = (int)height;
    }
    
    NSString *finalImgTag = [NSString stringWithFormat:@"<img src=\"%@\" height=\"%d\" width=\"%d\"/>", absoluteURLString, height, width];
  } else {
    // If we can't open the image, leave the tag as-is
    // It might be better to expunge the tag -- maybe it's an HTTP URL or something?  Not sure about this....
    finalImgTag = @"";
    *returnHeight = 0;
  }
  
  NSLog(@"returning str: %@", finalImgTag);
  return finalImgTag;
}

/**
 * Fixes all img tags within a given string.
 */
+(void)fixedHTMLStringForString:(NSMutableString *)theHTML filePath:(NSString *)thePath textSize:(int)size {
  BooksDefaultsController *defaults = [BooksDefaultsController sharedBooksDefaultsController];
  int thisImageHeight = 0;
  int height = 0;
  int i;
 
  NSString *basePath = [thePath stringByDeletingLastPathComponent];

  // Regex to find all img tags
  NSArray *imgTagMatches = [IMGTAG_REGEX findAllInString:theHTML];
  int imgCount = [imgTagMatches count];  
  
  // Loop over all the matches, and replace with the fixed version.
  for(i=0; i<imgCount; i++) {
    thisImageHeight = 0;
    AGRegexMatch *tagMatch = [imgTagMatches objectAtIndex:i];
    NSString *imgTag = [tagMatch group];
    NSString *fixedImgTag = [HTMLFixer fixedImageTagForString:imgTag basePath:basePath returnImageHeight:&thisImageHeight];

    NSRange origRange = [theHTML rangeOfString:imgTag];
    [theHTML replaceCharactersInRange:origRange withString:fixedImgTag];
    height += thisImageHeight;
  }
  
    
  //
  // There...  Image tags dealt with...
  //
  
  // Kill any styles or other difficult block elements (do this instead of just the @imports)
  [HTMLFixer replaceRegex:STYLE_REGEX withString:@"<hr style=\"height: 3px;\"/>" inMutableString:theHTML];

  // Adjust tables if desired.
  if(![defaults renderTables]) {
    // Use regex's to replace all table related tags with reasonably small-screen equivalents.
    // (Tip o' the hat to the Plucker folks for showing how to do it!)
    [HTMLFixer replaceRegex:TABLE_REGEX withString:@"<hr style=\"height: 3px;\"/>" inMutableString:theHTML];
    [HTMLFixer replaceRegex:TR_REGEX withString:@"" inMutableString:theHTML];
    [HTMLFixer replaceRegex:TD_REGEX withString:@"" inMutableString:theHTML];
    [HTMLFixer replaceRegex:TH_REGEX withString:@"<b>" inMutableString:theHTML];
    
    [HTMLFixer replaceRegex:TABLECL_REGEX withString:@"<hr style=\"height: 3px;\"/>" inMutableString:theHTML];
    [HTMLFixer replaceRegex:TRCL_REGEX withString:@"<hr style=\"height: 1px;\"/>" inMutableString:theHTML];
    [HTMLFixer replaceRegex:TDCL_REGEX withString:@"<br/>" inMutableString:theHTML];
    [HTMLFixer replaceRegex:THCL_REGEX withString:@"</b><br/><br/>" inMutableString:theHTML];
  }
  
  // Add a DIV object with a set height to make up for the images' height.
  // Is this still necessary under the newer firmwares, or does UIWebView have a clue now?
  if(height > 0) {
    [theHTML appendFormat:@"<div style=\"height: %dpx;\">&nbsp;<br/>&nbsp;<br/>&nbsp;<br/><br/>", height];
  }
}

/**
 * Replace all occurences of a regex with a static string in a mutable string.
 */
+ (void)replaceRegex:(AGRegex*)p_regex withString:(NSString*)p_repl inMutableString:(NSMutableString*)p_mut {
  // Do this in its own pool as the regex will likely alloc a lot of temporary memory.
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int i;
  
  // Regex to find everything
  NSArray *matches = [p_regex findAllInString:p_mut];
  int matchCount = [matches count];  
  
  // Loop over all the matches, and replace
  for(i=0; i<matchCount; i++) {
    AGRegexMatch *tagMatch = [matches objectAtIndex:i];
    NSString *sMatch = [tagMatch group];
    NSRange origRange = [p_mut rangeOfString:sMatch];
    [p_mut replaceCharactersInRange:origRange withString:p_repl];
  }
  
  [pool release];
}

@end
