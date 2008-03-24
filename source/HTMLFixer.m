// HTMLFixer.m, for Books.app by Zachary Brewster-Geisz
/* Most of this file is now obsolete.  Don't get excited if warnings
 from some of the methods appear on compile.  They're probably unused.
 */

#ifndef DESKTOP
# import <UIKit/UIKit.h>
# import <CoreGraphics/CoreGraphics.h>
# import "BooksDefaultsController.h"
#else
# import <Cocoa/Cocoa.h>
# define UIImage NSImage
#endif

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

//AGRegex *STYLEATT_REGEX;
//AGRegex *EMBEDSRCATT_REGEX;

// Assorted problematic block elements
AGRegex *STYLE_REGEX;
AGRegex *SCRIPT_REGEX;
AGRegex *OBJECT_REGEX;
AGRegex *FRAMESET_REGEX;
AGRegex *LINK_REGEX;
AGRegex *DOCTYPE_REGEX;
AGRegex *META_REGEX;

@implementation HTMLFixer

/**
 * Setup all the regex's we need.
 */
+ (void)initialize {
  // Image tag fixers
  SRC_REGEX = [[AGRegex alloc] initWithPattern:@"src=[\"']([^\\\"]+)[\"']" options:AGRegexCaseInsensitive];
  IMGTAG_REGEX = [[AGRegex alloc] initWithPattern:@"<img[^>]+>" options:AGRegexCaseInsensitive];
  
  // Open table elements
  TABLE_REGEX = [[AGRegex alloc] initWithPattern:@"<table[^>]*>" options:AGRegexCaseInsensitive];
  TR_REGEX = [[AGRegex alloc] initWithPattern:@"<tr[^>]*>" options:AGRegexCaseInsensitive];
  TD_REGEX = [[AGRegex alloc] initWithPattern:@"<td[^>]*>" options:AGRegexCaseInsensitive];
  TH_REGEX = [[AGRegex alloc] initWithPattern:@"<th[^>]*>" options:AGRegexCaseInsensitive];
  
  // Close table elements
  TABLECL_REGEX = [[AGRegex alloc] initWithPattern:@"</table[^>]*>" options:AGRegexCaseInsensitive];
  TRCL_REGEX = [[AGRegex alloc] initWithPattern:@"</tr[^>]*>" options:AGRegexCaseInsensitive];
  TDCL_REGEX = [[AGRegex alloc] initWithPattern:@"</td[^>]*>" options:AGRegexCaseInsensitive];
  THCL_REGEX = [[AGRegex alloc] initWithPattern:@"</th[^>]*>" options:AGRegexCaseInsensitive];
  
  // Attributes that need to be removed
  //STYLEATT_REGEX = [[AGRegex alloc] initWithPattern:@"style=\"[^\\\"]+\"" options:AGRegexCaseInsensitive];
  EMBEDSRCATT_REGEX = [[AGRegex alloc] initWithPattern:@"embedsrc=\"[^\\\"]+\"" options:AGRegexCaseInsensitive];
  
  // Assorted problematic block elements
  STYLE_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*(?:style|object|embed)[^<]+<[ \n\r]*/(?:style|object|embed)[^>]*>" options:AGRegexCaseInsensitive]; 
  SCRIPT_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*script[^>]*>.*?<[ \n\r]*/script[^>]*>" options:AGRegexCaseInsensitive];
  OBJECT_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*object[^>]*>.*?<[ \n\r]*/object[^>]*>" options:AGRegexCaseInsensitive];
  FRAMESET_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*frameset[^>]*>.*?<[ \n\r]*/frameset[^>]*>" options:AGRegexCaseInsensitive];
  LINK_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*link[^>]*>" options:AGRegexCaseInsensitive];
  DOCTYPE_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*!DOCTYPE[^>]*>" options:AGRegexCaseInsensitive];
  META_REGEX = [[AGRegex alloc] initWithPattern:@"(?s)<[ \n\r]*meta[^>]*>" options:AGRegexCaseInsensitive];
}

/**
 * Return YES if the image at the given path is an image.
 */
+ (BOOL)isDocumentImage:(NSString*)p_path {
	NSString *ext = [p_path pathExtension];
	return ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"]);
}

/**
 * Returns an image tag for which the image has been shrunk to MAXWIDTH pixels wide.
 * Changes the local file URL to an absolute URL since that's what the UITextView seems to like.
 * Does nothing if the image is already under MAXWIDTH px wide.
 * Assumes a local URL as the "src" element.
 */
#define MAXWIDTH 250
+(NSString *)fixedImageTagForString:(NSString *)aStr basePath:(NSString *)path returnImageHeight:(int *)returnHeight {
  // Build the final image tag from these:
  NSString *srcString = nil;
  unsigned int width = MAXWIDTH;
  unsigned int height = 0;
  
  // Use a regex to find the src attribute.
  AGRegexMatch *srcMatch = [SRC_REGEX findInString:aStr];
  if(srcMatch == nil || [srcMatch count] != 2) {
    // We didn't find a match, or we found MULTIPLE matches.  Just bail...
    return @"";
  } else {
    srcString = [srcMatch groupAtIndex:1];
    if([srcString length] == 0) {
      return @"";
    }
  }
  
  // Clean up the URL a bunch.
  //FIXME:  Should I worry about encodings?
  NSString *noPercentString = [srcString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
  NSString *imgPath = [[path stringByAppendingPathComponent:noPercentString] stringByStandardizingPath];
  NSURL *pathURL = [NSURL fileURLWithPath:imgPath];
  NSString *absoluteURLString = [pathURL absoluteString];
  
  NSString *finalImgTag;
  
  // Try to read the URL off the filesystem to get its height and width.
  UIImage *img = 
#ifndef DESKTOP
  [UIImage imageAtPath:imgPath];
#else
  [[[UIImage alloc] initByReferencingFile:imgPath] autorelease];
#endif
  
  if (nil != img) {
#ifndef DESKTOP    
    CGImageRef imgRef = [img imageRef];
    height = CGImageGetHeight(imgRef);
    width = CGImageGetWidth(imgRef);
#else
    height = [img size].height;
    width = [img size].width;
#endif
    if (width <= MAXWIDTH) {
      *returnHeight = (int)height;
    } else {
      float aspectRatio = (float)height / (float)width;
      width = MAXWIDTH;
      height = (unsigned int)((float)MAXWIDTH * aspectRatio);
      *returnHeight = (int)height;
    }
    
    finalImgTag = [NSString stringWithFormat:@"<img src=\"%@\" width=\"%d\" height=\"%d\" />", absoluteURLString, width, height];
  } else {
    // If we can't open the image, leave the tag as-is
    // It might be better to expunge the tag -- maybe it's an HTTP URL or something?  Not sure about this....
    finalImgTag = @"";
    *returnHeight = 0;
  }
   
  if(height > 0 || width > 0) {
    return finalImgTag;
  } else {
    return @"";
  }
  
}

/**
 * Fixes all img tags within a given string.
 *
 * @param theHTML NSMutableString containing HTML to be fixed.  HTML is fixed in place (param is modified)
 * @param thePath path of file (used for calculating base URL for images)
 * @param p_imgOnly YES skips most of the block-level fixing code.  Useful for Plucker or other formats which
 *    were synthesized using simplified HTML which only need image height/width fixing.
 */
+(void)fixHTMLString:(NSMutableString *)theHTML filePath:(NSString *)thePath imageOnly:(BOOL)p_imgOnly {
  int thisImageHeight = 0;
  int height = 0;
  int i;

  NSString *basePath = [thePath stringByDeletingLastPathComponent];
  
  // If we came from a simplified HTML format (Plucker), we don't need to do most of this stuff.
  if(!p_imgOnly) {
    // Kill any styles or other difficult block elements (do this instead of just the @imports)
    i = [HTMLFixer replaceRegex:STYLE_REGEX withString:@"" inMutableString:theHTML];
    i += [HTMLFixer replaceRegex:SCRIPT_REGEX withString:@"" inMutableString:theHTML];
    i += [HTMLFixer replaceRegex:OBJECT_REGEX withString:@"" inMutableString:theHTML];
    i += [HTMLFixer replaceRegex:LINK_REGEX withString:@"" inMutableString:theHTML];
    i += [HTMLFixer replaceRegex:DOCTYPE_REGEX withString:@"" inMutableString:theHTML];
    i += [HTMLFixer replaceRegex:META_REGEX withString:@"" inMutableString:theHTML];
    
    // FIXME: This kills any noframes section too, but it keeps Books from crashing.
    i += [HTMLFixer replaceRegex:FRAMESET_REGEX withString:@"" inMutableString:theHTML];
  
    [theHTML replaceOccurrencesOfString:@"embedsrc=" withString:@"invalid=" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [theHTML length])];

    // Kill style attributes - they can contain widths.
    //i += [HTMLFixer replaceRegex:STYLEATT_REGEX withString:@"" inMutableString:theHTML];
    i += [HTMLFixer replaceRegex:EMBEDSRCATT_REGEX withString:@"" inMutableString:theHTML];    
    
    // Adjust tables if desired.
    if(![HTMLFixer isRenderTables]) {
      // Use regex's to replace all table related tags with reasonably small-screen equivalents.
      // (Tip o' the hat to the Plucker folks for showing how to do it!)
      i=0;
      i += [HTMLFixer replaceRegex:TABLE_REGEX withString:[HTMLFixer tableStartReplacement] inMutableString:theHTML];
      i += [HTMLFixer replaceRegex:TR_REGEX withString:[HTMLFixer trStartReplacement] inMutableString:theHTML];
      i += [HTMLFixer replaceRegex:TD_REGEX withString:[HTMLFixer tdStartReplacement] inMutableString:theHTML];
      i += [HTMLFixer replaceRegex:TH_REGEX withString:[HTMLFixer thStartReplacement] inMutableString:theHTML];
      
      i += [HTMLFixer replaceRegex:TABLECL_REGEX withString:[HTMLFixer tableEndReplacement] inMutableString:theHTML];
      i += [HTMLFixer replaceRegex:TRCL_REGEX withString:[HTMLFixer trEndReplacement] inMutableString:theHTML];
      i += [HTMLFixer replaceRegex:TDCL_REGEX withString:[HTMLFixer tdEndReplacement] inMutableString:theHTML];
      i += [HTMLFixer replaceRegex:THCL_REGEX withString:[HTMLFixer thEndReplacement] inMutableString:theHTML];
    }
    
    // Check for missing opening html & body tags
    NSRange htmlRange = [theHTML rangeOfString:@"<html" options:NSCaseInsensitiveSearch];
    BOOL hasHtml = !(htmlRange.location == NSNotFound);
    BOOL hasBody = !([theHTML rangeOfString:@"<body" options:NSCaseInsensitiveSearch].location == NSNotFound);
            
    if(!hasBody) {
      if(!hasHtml) {
        [theHTML insertString:@"<html><body>" atIndex:0];
      } else {
        // Ugh....  Has HTML but no BODY.  Do we really need to deal with garbage html like this?
        // We'll assume the tag is <html> with no extra characters or attributed.  If that's not the case, 
        // this will probably make a horrible mess of things.  There's only so much we can do with invalid HTML...
        [theHTML insertString:@"<body>" atIndex:htmlRange.location+2]; // 1 for the close bracket we didn't search for above +  1 for the next char
      }
    } else if(!hasHtml) {
      [theHTML insertString:@"<html>" atIndex:0];
    }
    
    // Check for missing closing html & body tags
    NSRange cHtmlRange = [theHTML rangeOfString:@"</html" options:NSCaseInsensitiveSearch];
    BOOL hascBody = !([theHTML rangeOfString:@"</body" options:NSCaseInsensitiveSearch].location == NSNotFound);
    BOOL hascHtml = !(cHtmlRange.location == NSNotFound);
    
    if(!hascHtml) {
      if(!hascBody) {
        [theHTML appendString:@"</body></html>"];
      } else {
        [theHTML appendString:@"</html>"];
      }
    } else if(!hascBody) {
      // It has an html but no body.
      [theHTML insertString:@"</body>" atIndex:cHtmlRange.location];
    }
  }  
  
  
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
  
  NSRange cBodyRange = [theHTML rangeOfString:@"</body" options:NSCaseInsensitiveSearch];
  
  // Fix for truncated files (usually caused by invalid HTML).
  [theHTML insertString:@"<p>&nbsp;</p><p>&nbsp;</p>" atIndex:cBodyRange.location];
}

/**
 * Replace all occurences of a regex with a static string in a mutable string.
 */
+ (int)replaceRegex:(AGRegex*)p_regex withString:(NSString*)p_repl inMutableString:(NSMutableString*)p_mut {
  // Do this in its own pool as the regex will likely alloc a lot of temporary memory.
  //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
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

  //[pool release];
  
  return matchCount;
}

/**
 * Return NO if we need special table handling.
 */
+ (BOOL)isRenderTables {
#ifndef DESKTOP
  return [[BooksDefaultsController sharedBooksDefaultsController] renderTables];
#else
  return NO;
#endif
}

+ (NSString*)tableStartReplacement {
  return @"<hr style=\"height: 3px;\"/>";
}

+ (NSString*)tdStartReplacement {
  return @"";
}

+ (NSString*)trStartReplacement {
  return @"";
}

+ (NSString*)thStartReplacement {
  return @"<b>";
}

+ (NSString*)tableEndReplacement {
  return @"<hr style=\"height: 3px;\"/>";
}

+ (NSString*)tdEndReplacement {
  return @"<br/>";
}

+ (NSString*)trEndReplacement {
  return @"<hr style=\"height: 1px;\"/>";
}
+ (NSString*)thEndReplacement {
  return @"</b><br/><br/>";
}

@end
