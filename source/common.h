// common.h, for Books.app
/*

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


#ifndef COMMON_H
#define COMMON_H

/** Stdout will be dumped here if the file exists at startup. */
#define OUT_FILE @"/var/logs/Books.out"

/** appended to the home directory to create the real EBooksPath. */
#define EBOOK_PATH_SUFFIX @"Media/EBooks"
#define LIBRARY_PATH @"Library/Books"

#define MIN_FONT_SIZE 10.0f
#define MAX_FONT_SIZE 36.0f

#define TOOLBAR_FUDGE 20.0f
#define TOOLBAR_HEIGHT 48.0f
#define PREFS_TABLE_ROW_HEIGHT 48.0f

/* FIXME: It would be rather nice if we could eliminate as much dependence on notifications as possible. */
#define AUTOMATIC_ENCODING (0)
#define ENCODINGSELECTED @"encodingSelectedNotification"
#define NEWFONTSELECTED @"newFontSelectedNotification"
#define CHANGEDSCROLLSPEED @"scrollSpeedChangedNotification"

#define OPENEDTHISFILE @"openedThisFileNotification"
#define RELOADTOPBROWSER @"reloadTopBrowserNotification"
#define TOOLBAR_DEFAULTS_CHANGED_NOTIFICATION @"toolbarDefaultsChanged"

#define WEBSITE_URL_STRING @"http://iphoneebooks.googlecode.com/"
#define PERMISSION_HELP_URL_STRING @"http://code.google.com/p/iphoneebooks/wiki/Troubleshooting113"

#endif

