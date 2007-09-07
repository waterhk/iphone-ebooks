CC=arm-apple-darwin-cc
LD=$(CC)
LDFLAGS=-lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework LayerKit -framework CoreGraphics -framework GraphicsServices

all:    Books

Books:  mainapp.o BooksApp.o EBookView.o FileBrowser.o FileTable.o \
	BooksDefaultsController.o HideableNavBar.o PreferencesController.o \
	EncodingPrefsController.o
	$(LD) $(LDFLAGS) -v -o $@ $^

%.o:    %.m 
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

%.m:    %.h


clean:
		rm -rf *.o *~ Books Books.app

package: Books
	rm -fr Books.app
	mkdir -p Books.app
	cp Books Books.app/Books
	cp Info.plist Books.app/Info.plist
	cp icon.png Books.app/icon.png
	cp Default.png Books.app/Default.png
	cp PkgInfo Books.app/PkgInfo
	cp inv_up.png Books.app/inv_up.png
	cp inv_down.png Books.app/inv_down.png
	cp embig_up.png Books.app/embig_up.png
	cp embig_down.png Books.app/embig_down.png
	cp emsmall_up.png Books.app/emsmall_up.png
	cp emsmall_down.png Books.app/emsmall_down.png
	cp prefs_up.png Books.app/prefs_up.png
	cp prefs_down.png Books.app/prefs_down.png
	cp down_down.png Books.app/down_down.png	
	cp down_up.png Books.app/down_up.png	
	cp up_down.png Books.app/up_down.png
	cp up_up.png Books.app/up_up.png
	cp left_down.png Books.app/left_down.png
	cp left_up.png Books.app/left_up.png
	cp right_down.png Books.app/right_down.png
	cp right_up.png Books.app/right_up.png
	cp UnreadIndicator.png Books.app/UnreadIndicator.png
	cp ReadIndicator.png Books.app/ReadIndicator.png
