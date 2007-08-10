CC=arm-apple-darwin-cc
LD=$(CC)
LDFLAGS=-lobjc -framework CoreFoundation -framework Foundation -framework UIKit -framework LayerKit -framework CoreGraphics -framework GraphicsServices

all:    Books

Books:  mainapp.o BooksApp.o EBookView.o FileBrowser.o
	$(LD) $(LDFLAGS) -v -o $@ $^

%.o:    %.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f *.o Books