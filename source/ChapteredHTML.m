/* ChapteredHTML.m, by John A. Whitney for Books.app

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
#import <stdio.h>
#import <string.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <unistd.h>
#import <openssl/sha.h>
#import <Foundation/NSDictionary.h>
#import "ChapteredHTML.h"
#import "Regex.h"
#import <Foundation/Foundation.h>

#define ARRAY_SIZE(x)   (sizeof (x) / sizeof ((x)[0]))

@implementation ChapteredHTML

- (id) init
{
	_fullHTML = nil;
}

- (void) dealloc
{
	[_fullHTML release];
	[super dealloc];
}

- (void) setHTML: (NSString *) html
{
	NSMutableString *filename = [[NSMutableString alloc] initWithCapacity:80];
	int              index;

	[_fullHTML release];
	_fullHTML = [html retain];

	if (html == nil)
	{
		_fullHTML = nil;

		_headerRange.location   = 0;
		_headerRange.length     = 0;
		_bodyRange.location     = 0;
		_bodyRange.length       = 0;
		_trailerRange.location  = 0;
		_trailerRange.length    = 0;

		return;
	}

	SHA1 ((const unsigned char *) [_fullHTML UTF8String],
	      (unsigned long) [_fullHTML length],
	      _fullHTMLHash);
	NSString *lDirName = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Caches/Books/"];
	filename = [[NSMutableString alloc] initWithString:lDirName];
	for (index = 0; index < sizeof (_fullHTMLHash); index++)
		[filename appendFormat:@"%02x", _fullHTMLHash[index]];
	[filename appendString:@".plist"];

	if ([self loadFromFile:filename] == NO)
	{
		[self findSections];
		[self findChapters];
		[self saveToFile:filename];
	}
	[filename release];

	return;
}

- (int) chapterCount
{
	return _chapterCount;
}

- (NSString *) getHTML
{
	return _fullHTML;
}

- (NSString *) getChapterHTML: (int) chapter
{
	NSMutableString *string;
	
	if (chapter >= _chapterCount)
	{
		return @"<html><body></body></html>";
	}

	string = [[NSMutableString alloc] initWithCapacity:_headerRange.length +
	                                                   _chapterRange[chapter].length +
	                                                   _trailerRange.length +
	                                                   8];
	[string setString:[_fullHTML substringWithRange:_headerRange]];
	[string appendString:[_fullHTML substringWithRange:_chapterRange[chapter]]];
	[string appendString:@"<br><br>"];
	[string appendString:[_fullHTML substringWithRange:_trailerRange]];

FILE *file = fopen ("/tmp/book.html", "w");
fprintf (file, "%s\n", [string UTF8String]);
fclose (file);
	return [string autorelease];
}

- (BOOL) loadFromFile: (NSString *) filename
{
	NSDictionary *dictionary;
	NSDictionary *chapterRanges;
	NSNumber     *start;
	NSNumber     *length;
	NSNumber     *number;
	int           index;

	dictionary = [NSDictionary dictionaryWithContentsOfFile:filename];
	if (dictionary == nil)
		return NO;

	/* Header Range */
	start  = [dictionary objectForKey:@"headerStart"];
	length = [dictionary objectForKey:@"headerLength"];
	if (!start || !length)
		return NO;

	_headerRange.location = [start unsignedIntValue];
	_headerRange.length   = [length unsignedIntValue];

	/* Body Range */
	start  = [dictionary objectForKey:@"bodyStart"];
	length = [dictionary objectForKey:@"bodyLength"];
	if (!start || !length)
		return NO;

	_bodyRange.location = [start unsignedIntValue];
	_bodyRange.length   = [length unsignedIntValue];

	/* Trailer Range */
	start  = [dictionary objectForKey:@"trailerStart"];
	length = [dictionary objectForKey:@"trailerLength"];
	if (!start || !length)
		return NO;

	_trailerRange.location = [start unsignedIntValue];
	_trailerRange.length   = [length unsignedIntValue];

	/* Chapter Count */
	number = [dictionary objectForKey:@"chapterCount"];
	if (number == nil)
		return NO;

	_chapterCount = [number unsignedIntValue];

	chapterRanges = [dictionary objectForKey:@"chapterRanges"];
	if ((chapterRanges == nil) || ([chapterRanges count] != _chapterCount))
		return NO;

	for (index = 0; index < [chapterRanges count]; index++)
	{
		NSString     *chapterNum = [NSString stringWithFormat:@"%d", index];
		NSDictionary *chapter    = [chapterRanges objectForKey:chapterNum];

		if (chapter == nil)
			return NO;

		/* Trailer Range */
		start  = [chapter objectForKey:@"start"];
		length = [chapter objectForKey:@"length"];
		if (!start || !length)
			return NO;

		_chapterRange[index].location = [start unsignedIntValue];
		_chapterRange[index].length   = [length unsignedIntValue];
	}

	return YES;
}

- (void) saveToFile: (NSString *) filename
{
	int                  index;
	NSString            *path;
	NSMutableDictionary *dictionary;
	NSMutableDictionary *chapterRanges;
	NSMutableDictionary *chapter;
	
	for (index = [filename length] - 1; index > 1; index--)
		if ([filename characterAtIndex:index] == (unichar) '/')
			break;

	path = [filename substringToIndex:index];
	mkdir ([path cString], 0755);

	dictionary    = [[NSMutableDictionary alloc] initWithCapacity:10];
	chapterRanges = [[NSMutableDictionary alloc] initWithCapacity:10];

	[dictionary setObject:[NSNumber numberWithUnsignedInt:_headerRange.location]
	               forKey:@"headerStart"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_headerRange.length]
	               forKey:@"headerLength"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_bodyRange.location]
	               forKey:@"bodyStart"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_bodyRange.length]
	               forKey:@"bodyLength"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_trailerRange.location]
	               forKey:@"trailerStart"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_trailerRange.length]
	               forKey:@"trailerLength"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_chapterCount]
	               forKey:@"chapterCount"];
	for (index = 0; index < _chapterCount; index++)
	{
		NSRange *range = &_chapterRange[index];

		chapter = [[NSMutableDictionary alloc] initWithCapacity:2];
		[chapter setObject:[NSNumber numberWithUnsignedInt:range->location]
		            forKey:@"start"];
		[chapter setObject:[NSNumber numberWithUnsignedInt:range->length]
		            forKey:@"length"];
		[chapterRanges setObject:chapter
		                  forKey:[NSString stringWithFormat:@"%d", index]];
		[chapter release];
	}
	[dictionary setObject:chapterRanges forKey:@"chapterRanges"];
	[chapterRanges release];
	      
    if ([dictionary writeToFile:filename atomically:NO] == YES)
    	GSLog (@"Wrote cachefile: %s", [filename cString]);
    else
    	GSLog (@"Unable to write cachefile: %s", [filename cString]);

	[dictionary release];
}

- (void) findSections
{
	NSString *bodyIdentifier    = @"<body";
	NSString *trailerIdentifier = @"</body>";

	_bodyRange.location   = 0;
	_bodyRange.length     = [bodyIdentifier length];

	/*
	 * Find "<body" within the HTML text.
	 */
	while (_bodyRange.location < ([_fullHTML length] - _bodyRange.length))
	{
		NSString *substr = [_fullHTML substringWithRange:_bodyRange];
		if ([substr caseInsensitiveCompare:bodyIdentifier] == NSOrderedSame)
			break;

		_bodyRange.location += 1;
	}

	/*
	 * Look for the end of the <body...> block.
	 */
	while ((_bodyRange.location < [_fullHTML length]) &&
	       ([_fullHTML characterAtIndex:_bodyRange.location] != (unichar) '>'))
	{
		_bodyRange.location += 1;
	}
	_bodyRange.location += 1;

	/*
	 * If not found, clear out everything and exit.
	 */
	if (_bodyRange.location >= [_fullHTML length])
	{
		_headerRange.location   = 0;
		_headerRange.length     = 0;
		_bodyRange.location     = 0;
		_bodyRange.length       = 0;
		_trailerRange.location  = 0;
		_trailerRange.length    = 0;
		return;
	}
	            
	/*
	 * Find the start of the trailer by looking for "</body>" starting at
	 * the end of the HTML.
	 */
	_trailerRange.length   = [trailerIdentifier length];
	_trailerRange.location = [_fullHTML length] - _trailerRange.length;

	while (_trailerRange.location > _bodyRange.location)
	{
		NSString *substr = [_fullHTML substringWithRange:_trailerRange];
		if ([substr caseInsensitiveCompare:trailerIdentifier] == NSOrderedSame)
			break;

		_trailerRange.location -= 1;
	}

	if (_trailerRange.location == _bodyRange.location)
	{
		_headerRange.location  = 0;
		_headerRange.length    = 0;
		_bodyRange.location    = 0;
		_bodyRange.length      = 0;
		_trailerRange.location = 0;
		_trailerRange.length   = 0;
		return;
	}

	/*
	 * Calculate full ranges.
	 */
	_headerRange.location = 0;
	_headerRange.length   = _bodyRange.location;
	/* _bodyRange.location already set... */
	_bodyRange.length     = (_trailerRange.location - _bodyRange.location);
	/* _trailerRange.location already set... */
	_trailerRange.length  = ([_fullHTML length] - _trailerRange.location);

	return;
}

- (void) findChapters
{
	int      lastChapterOffset = _bodyRange.location;
	int      index;
	Regex   *regexArray[2];
	int      regexIndex;

	if (_bodyRange.length == 0)
	{
		_chapterRange[0].location = 0;
		_chapterRange[0].length   = [_fullHTML length];
		_chapterCount = 1;
		return;
	}

	regexArray[0] = [[Regex alloc] initWithString:@"<p class=\"p?\"><b>+</b></p>"];
	regexArray[1] = [[Regex alloc] initWithString:@"<h[123456789]+</h*>"];

	_chapterCount = 0;
	_chapterRange[0].location = _bodyRange.location;

	for (index = 0;
	     (index < _bodyRange.length) &&
	     (_chapterCount < (MAX_CHAPTERS - 2));
	     index++)
	{
		int     offset = (_bodyRange.location + index);
		unichar chr    = [_fullHTML characterAtIndex:offset];

		for (regexIndex = 0;
		     (regexIndex < ARRAY_SIZE (regexArray)) &&
		     (_chapterCount < (MAX_CHAPTERS - 2));
		     regexIndex++)
		{
			Regex *regex = regexArray[regexIndex];

			[regex addCharacter:chr];
			if ([regex wasCompleted])
			{
				offset -= [regex matchedChars] - 1;

				if (((offset - lastChapterOffset) > 2048) &&
				    ((_trailerRange.location - offset) > 2048))
				{
					_chapterCount += 1;

					_chapterRange[_chapterCount].location = offset;
					_chapterRange[_chapterCount - 1].length =
						_chapterRange[_chapterCount].location -
						_chapterRange[_chapterCount - 1].location;
					lastChapterOffset = offset;

					NSRange chapterNameRange = { offset, [regex matchedChars] };
					NSString *chapterName =
						[_fullHTML substringWithRange:chapterNameRange];
					GSLog (@"Chapter %2d (offset %6d): '%s'\n",
					       _chapterCount,
					       offset,
					       [chapterName UTF8String]);
				}

				[regex clear];
			}
		}
	}

	_chapterRange[_chapterCount].length = _trailerRange.location -
	                                      _chapterRange[_chapterCount].location;
	_chapterCount += 1;

	[regexArray[0] release];
	[regexArray[1] release];
	return;
}

@end
