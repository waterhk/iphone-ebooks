// HTMLFixer.m, for Books.app by Zachary Brewster-Geisz


#include "HTMLFixer.h"

@implementation HTMLFixer

+(BOOL)fileHasBeenFixedAtPath:(NSString *)path
// Returns YES if the file has already been processed by HTMLFixer.
// Returns NO if it hasn't, or there was an error reading the file.
{
    NSFileHandle *theFile = [NSFileHandle fileHandleForReadingAtPath:path];
	if (nil != theFile)
        {
            NSData *beginningData = [[theFile readDataOfLength:24] retain];
            NSString *beginningString = [[NSString alloc] initWithData:beginningData
                                                encoding:NSUTF8StringEncoding];
            if (nil != beginningString)
                {
                    BOOL ret = [[beginningString substringWithRange:NSMakeRange(0, 12)]
                                  isEqualToString:@"<!--BooksApp"];
                    [beginningString release];
                    return ret;
                }
        }
    return NO;
}

+(BOOL)writeFixedFileAtPath:(NSString *)thePath
// Fixes the given HTML file and rewrites it.  Returns YES if successful, NO otherwise.
// You should always call +fileHasBeenFixed first to see if this method is needed.
//FIXME: use the user-defined text encoding, if applicable.
{
    NSMutableString *theHTML = [[NSMutableString alloc] initWithContentsOfFile:thePath
                                            encoding:NSUTF8StringEncoding
                                            error:NULL];
    BOOL ret;
/*  if (nil == theHTML)
    {
      NSLog(@"Trying UTF-8 encoding...");
      theHTML = [[NSMutableString alloc]
               initWithContentsOfFile:thePath
               encoding: NSUTF8StringEncoding
               error:NULL];
    }
*/    if (nil == theHTML)
    {
      NSLog(@"Trying ISO Latin-1 encoding...");
      theHTML = [[NSMutableString alloc]
               initWithContentsOfFile:thePath
               encoding: NSISOLatin1StringEncoding
               error:NULL];
    }
    if (nil == theHTML)
    {
      NSLog(@"Trying Mac OS Roman encoding...");
      theHTML = [[NSMutableString alloc]
               initWithContentsOfFile:thePath
               encoding: NSMacOSRomanStringEncoding
               error:NULL];
    }
    if (nil == theHTML)
    {
      NSLog(@"Trying ASCII encoding...");
      theHTML = [[NSMutableString alloc] 
               initWithContentsOfFile:thePath
               encoding: NSASCIIStringEncoding
               error:NULL];
    }
    if (nil == theHTML)  // Give up.  The webView will still display it.
        return NO;
    NSMutableString *newHTML = [NSMutableString stringWithString:[HTMLFixer fixedHTMLStringForString:theHTML filePath:thePath]];
    NSString *temp = [NSString stringWithFormat:@"<!--BooksApp modified %@ -->\n",
                        [NSCalendarDate calendarDate]];
    [newHTML insertString:temp atIndex:0];
    ret = [newHTML writeToFile:thePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [theHTML release];
    return ret;
}

+(NSString *)fixedImageTagForString:(NSString *)aStr basePath:(NSString *)path returnImageHeight:(int *)returnHeight
// Returns an image tag for which the image has been shrunk to 300 pixels wide.
// Changes the local file URL to an absolute URL since that's what the
// UITextView seems to like.
// Does nothing if the image is already under 300 px wide.
// Assumes a local URL as the "src" element.
{
    NSMutableString *str = [NSMutableString stringWithString:aStr];
    unsigned int len = [str length];
    NSRange range;
    NSString *tempString;
    unsigned int c = 0;
    unsigned int d = 0;
    unsigned int width = 300;
    unsigned int height = 0;
    NSString *srcString = nil;
    NSRange pathRange;
    // First step, find the "src" string.
    while (c + 4 < len)
        {
            range = NSMakeRange(c++, 4);
            tempString = [[str substringWithRange:range] lowercaseString];
            if ([tempString isEqualToString:@"src="])
                {
                    pathRange = [str quotedRangePastIndex:c];
		    if (pathRange.location == NSNotFound)
		      srcString = nil;
		    else
		      srcString = [str substringWithRange:pathRange];
		    //NSLog(@"srcString: %@", srcString);
                    //With any luck, this will be the file name.
                    break;
                }
        }
    if (srcString == nil)
        return [aStr copy];
    NSString *imgPath = [[path stringByAppendingPathComponent:srcString] stringByStandardizingPath];
    NSURL *pathURL = [NSURL fileURLWithPath:imgPath];
    NSString *absoluteURLString = [pathURL absoluteString];
    //NSLog(@"absoluteURLString: %@", absoluteURLString);
    [str replaceCharactersInRange:pathRange withString:absoluteURLString];
    //here's hopin'!


    UIImage *img = [UIImage imageAtPath:imgPath];
    if (nil != img)
        {
            CGImageRef imgRef = [img imageRef];
            height = CGImageGetHeight(imgRef);
            width = CGImageGetWidth(imgRef);
	    //NSLog(@"image's width: %d height: %d", width, height);
            if (width <= 300)
	      {
		*returnHeight = (int)height;
                return [NSString stringWithString:str];
	      }
            float aspectRatio = (float)height / (float)width;
            width = 300;
            height = (unsigned int)(300.0 * aspectRatio);
	    *returnHeight = (int)height;
        }
    // Now, find if there's a "height" tag.
    c = 0;
    while (c + 8 < len)
        {
            range = NSMakeRange(c++, 7);
            tempString = [[str substringWithRange:range] lowercaseString];
            if ([tempString isEqualToString:@"height="])
                {
		  NSRange anotherRange = [str quotedRangePastIndex:c];
		  NSString *heightNumString = [NSString stringWithFormat:@"%d", (int)height];
		  if (anotherRange.location != NSNotFound)
		    [str replaceCharactersInRange:anotherRange withString:heightNumString];
		  len = [str length];

		  break;
                }
        }
    // If there's no height tag, we don't need to worry about inserting one.
    // Now, to find the width tag.
    c = 0;
    BOOL foundWidth = NO;
    while (c + 7 < len)
        {
            range = NSMakeRange(c++, 6);
            tempString = [[str substringWithRange:range] lowercaseString];
            if ([tempString isEqualToString:@"width="])
	      {
                    foundWidth = YES;
		    NSRange anotherRange = [str quotedRangePastIndex:c];
                    NSString *widthNumString = [NSString stringWithFormat:@"%d", (int)width];
		    if (anotherRange.location != NSNotFound)
		      [str replaceCharactersInRange:anotherRange withString:widthNumString];
                    len = [str length];
                    break;
                }
        }
    if (!foundWidth)
    // There was no width tag, so let's just insert one.
        {
            NSString *widthString = [NSString stringWithFormat:@" width=\"%d\" ", (int)width];
            [str insertString:widthString atIndex:4];
        }
    NSLog(@"returning str: %@", str);
    return [NSString stringWithString:str];
}

+(NSString *)fixedHTMLStringForString:(NSString *)theOldHTML filePath:(NSString *)thePath addedHeight:(int *)height
  // Fixes all img tags within a given string
{
  NSMutableString *theHTML = [NSMutableString stringWithString:theOldHTML];
  int thisImageHeight = 0;
    unsigned int c = 0;
    unsigned int len = [theHTML length];
    while (c < len)
        {
            if ([theHTML characterAtIndex:c] == (unichar)'<')
                {
                    NSString *imgString = [[theHTML substringWithRange:NSMakeRange(c+1, 3)]
                        lowercaseString];
                    if ([imgString isEqualToString:@"img"])
                        {
                            unsigned int d = c++;
                            while ((c < len) && ([theHTML characterAtIndex:c] != (unichar)'>'))
                                c++;
                            NSRange aRange = NSMakeRange(d, (c - d));
                            NSString *imageTagString = [theHTML substringWithRange: aRange];
                            [theHTML replaceCharactersInRange:aRange
                                 withString:[HTMLFixer fixedImageTagForString:imageTagString
                                                        basePath:[thePath stringByDeletingLastPathComponent]
						       returnImageHeight:&thisImageHeight]];
                            len = [theHTML length];
			    *height += thisImageHeight;
			    thisImageHeight = 0;
                        }
                }
            ++c;
        }
        
    return [NSString stringWithString:theHTML];
}
@end
