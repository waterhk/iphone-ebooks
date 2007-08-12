CC=arm-apple-darwin-cc
LD=$(CC)
LDFLAGS=-lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework LayerKit -framework CoreGraphics -framework GraphicsServices

all:    Books

Books:  mainapp.o BooksApp.o EBookView.o FileBrowser.o EBookNavItem.o
	$(LD) $(LDFLAGS) -v -o $@ $^

%.o:    %.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f *.o Books

package: Books
	rm -fr Books.app
	mkdir -p Books.app
	cp Books Books.app/Books
	cp Info.plist Books.app/Info.plist
	cp icon.png Books.app/icon.png
	cp Default.png Books.app/Default.png
	cp PkgInfo Books.app/PkgInfo