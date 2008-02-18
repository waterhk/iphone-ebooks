/* Regex.m, by John A. Whitney for Books.app

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
#import <stdlib.h>
#import <string.h>
#import <wctype.h>
#import "Regex.h"

@implementation Regex

- (id) initWithString: (NSString *) string
{
	if (string == nil)
	{
		[self release];
		return nil;
	}

	_origString      = [string retain];
	_string          = [[string lowercaseString] retain];
	_caseInsensitive = YES;
	[self clear];

	return self;
}

- (void) dealloc
{
	[_origString release];
	[_string release];

	[super dealloc];
	return;
}

- (void) clear
{
	_index            =  0;
	_matchIndex       =  0;
	_lastExpIndex     = -1;
	_matchChrBegIndex = -1;
	_matchExpBegIndex = -1;
	_matchExpEndIndex = -1;
}

- (void) restart
{
	unichar *savedCharacters;
	int      chars = _matchIndex - 1;
	int      index;

	if (chars <= 0)
		[self clear];
	else
	{
		savedCharacters = malloc (sizeof (_matchChars));
		memcpy (savedCharacters, &_matchChars[1], chars * sizeof (unichar));
		[self clear];

		for (index = 0; index < chars; index++)
			[self addCharacter:savedCharacters[index]];

		free (savedCharacters);
	}

	return;
}

- (void) addCharacter: (unichar) chr
{
	int latestMatchIndex = _matchIndex;

	if (_caseInsensitive)
		chr = (unichar) towlower ((wint_t) chr);

	/* Add one to the characters processed in this regex. */
	_matchChars[_matchIndex++] = chr;
	if (_matchIndex == sizeof (_matchChars))
	{
		[self restart];
		return;
	}

	if (_index >= [_string length])
		return;

	/* [ = set of characters, one of which must match, terminated by ] */
	if ([_string characterAtIndex:_index] == (unichar) '[')
	{
		int i;

		for (i = (_index + 1);
		     [_string characterAtIndex:i] != (unichar) ']';
		     i++)
		{
			if (chr == [_string characterAtIndex:i])
				break;
		}

		if ([_string characterAtIndex:i] == (unichar) ']')
			[self restart];
		else
		{
			/* Advance the index to beyond the ] terminator */
		    while ([_string characterAtIndex:_index++] != (unichar) ']')
		    	;
		}
	}

	/* ? = one and only one character */
	else if ([_string characterAtIndex:_index] == (unichar) '?')
		_index += 1;

	/* * = zero or one character */
	else if ([_string characterAtIndex:_index] == (unichar) '*')
	{
		if (_matchChrBegIndex == -1)
			_matchChrBegIndex = _matchIndex;

		if (chr == [_string characterAtIndex:(_index + 1)])
		{
			_matchChrBegIndex = -1;
			_index += 2;
		}
		else if ((_matchIndex - _matchChrBegIndex) >= 2)
		{
			[self restart];
		}
	}

	/* + = zero to 80 characters */
	else if ([_string characterAtIndex:_index] == (unichar) '+')
	{
		_lastExpIndex = _index;

		if (_matchExpBegIndex == -1)
			_matchExpBegIndex = _matchIndex;

		if (chr == [_string characterAtIndex:(_index + 1)])
		{
			_matchExpEndIndex = latestMatchIndex;
			_index += 2;
		}
		else if ((_matchIndex - _matchExpBegIndex) >= 80)
		{
			[self restart];
		}
	}

	/* Otherwise, match the character exactly */
	else if (chr == [_string characterAtIndex:_index])
		_index += 1;

	/* If no match, but we've had an expression we might continue, try it now */
	else if (_lastExpIndex != -1)
	{
		unichar *savedCharacters = malloc (sizeof (_matchChars));
		int      chars = 0;
		int      index;

		for (index = _matchExpEndIndex;
		     index < _matchIndex;
		     index++)
		{
			savedCharacters[chars++] = _matchChars[index];
		}

		_index = _lastExpIndex;
		_matchIndex = _matchExpEndIndex + 1;

		for (index = 1; index < chars; index++)
			[self addCharacter:savedCharacters[index]];

		free (savedCharacters);
	}

	/* If no match, we have to start over. */
	else
	{
		[self restart];
	}

	return;
}

- (BOOL) wasCompleted
{
	return (_index >= [_string length]) ? YES : NO;
}

- (int) matchedChars
{
	return _matchIndex;
}

- (void) setCaseSensitive: (BOOL) sensitive
{
	[_string release];

	if (sensitive == YES)
		_string = [_origString retain];
	else
		_string = [[_origString lowercaseString] retain];

	return;
}
@end
