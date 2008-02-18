/* Regex.h, by John A. Whitney for Books.app

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
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@interface Regex : NSObject
{
	NSString *_origString;   /* original regular expression string to match */
	NSString *_string;       /* case-adjusted reg. expr. string to match */
	int       _index;        /* current match point within 'string' */

	int       _lastExpIndex; /* index of last variable-char expresiion */

	unichar   _matchChars[128]; /* current matching bytes */
	int       _matchIndex;      /* index for matchChars */
	int       _matchChrBegIndex;/* index of character that started char. */
	int       _matchExpBegIndex;/* index of character that started expr. */
	int       _matchExpEndIndex;/* index of character that ended expression */

	BOOL      _caseInsensitive; /* should case be ignored? */
}

- (id) initWithString: (NSString *) string;
- (void) dealloc;

- (void) clear;
- (void) restart;
- (void) addCharacter: (unichar) chr;
- (BOOL) wasCompleted;
- (int) matchedChars;
- (void) setCaseSensitive: (BOOL) sensitive;

@end
