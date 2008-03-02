#  
# Books.app Makefile
#

CC=arm-apple-darwin-gcc
CFLAGS=-O3
CPPFLAGS=-I/opt/local/include
LD=$(CC)
LDFLAGS=-L$(HEAVENLY)/usr/lib -L/usr/local/lib/gcc/arm-apple-darwin/4.0.1 \
	-lz -lobjc -lgcc -framework CoreFoundation -framework Foundation \
	-framework UIKit -framework LayerKit -framework CoreGraphics \
	-framework GraphicsServices -lcrypto

VERSION=$(shell ./getversion.sh)

SOURCES=$(wildcard source/palm/*.c source/palm/*.m source/*.c source/*.m)
OBJECTS=$(patsubst source/%,obj/%,$(patsubst source/palm/%,obj/%, \
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES))) \
	$(patsubst %.cpp,%.o,$(filter %.cpp,$(SOURCES))) \
))

# Override this on the command line for nightly builds.
REPOTAG=Repository in Exile

IMAGES=$(wildcard images/*.png)

ARCHIVE=Books-$(VERSION).zip

BASEURL=http://www.thebedells.org/books/
SCP_BASE=www:~/wwwroot/books/
NIGHTLY_PICKUP=/tmp/Books-nightly

QUIET=false

ifeq ($(QUIET),true)
	QC	= @echo "Compiling [$@]";
	QD	= @echo "Computing dependencies [$@]";
	QL	= @echo "Linking   [$@]";
	QN	= > /dev/null 2>&1
else
	QC	=
	QD	=
	QL	= 
	QN	=
endif

all:    Books


# pull in dependency info for *existing* .o files
# this needs to be done after the default target is defined (to avoid defining a meaningless default target)
-include $(OBJECTS:.o=.d)

test:
	echo $(OBJECTS)
	
bundle: Books.app

Books: obj/Books

obj/Books:  $(OBJECTS) lib/libjpeg.a
	$(QL)$(LD) $(LDFLAGS) -v -o $@ $^ $(QN)

# more complicated dependency computation, so all prereqs listed
# will also become command-less, prereq-less targets
#   sed:    put the real target (obj/*.o) in the dependency file
#   sed:    strip the target (everything before colon)
#   sed:    remove any continuation backslashes
#   fmt -1: list words one per line
#   sed:    strip leading spaces
#   sed:    add trailing colons
obj/%.o:    source/%.m
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $<  > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

obj/%.o:    source/%.c
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $< > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

obj/%.o:    source/palm/%.m 
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $< > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

obj/%.o:    source/palm/%.c
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $< > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

clean:
	rm -rf obj Books.app Books-*.tbz Books-*.zip repo.xml repo.xml.gz
	
obj/Info.plist: Info.plist.tmpl
	@echo "Building Info.plist for version $(VERSION)."
	@sed -e 's|__VERSION__|$(VERSION)|g' < $< > $@

repo.xml: repo.xml.tmpl package
	sed -e 's|__VERSION__|$(VERSION)|g' \
		-e 's|__PKG_SIZE__|$(shell ./filesize.sh $(ARCHIVE))|g' \
		-e 's|__RELEASE_DATE__|$(shell date +%s)|g' \
		-e 's|__PKG_URL__|$(BASEURL)$(ARCHIVE)|g' \
		-e 's|__REPOTAG__| $(REPOTAG)|g' \
		-e 's|__MD5__|$(shell ./getMd5.sh $(ARCHIVE))|g' \
		-e 's/^[[:space:]]*\(\([[:space:]]*[^[:space:]][^[:space:]]*\)*\)[[:space:]]*$($)/\1/' \
		< repo.xml.tmpl > $@
	gzip -9 < $@ > $@.gz

Books.app: obj/Books obj/Info.plist $(IMAGES)
	@echo "Creating application bundle."
	@rm -fr Books.app
	@mkdir -p Books.app
	@cp $^ Books.app/
#	@rm Books.app/Default.png
#	@ln  -f -s '~/Library/Books/Default.png' Books.app/Default.png
	
deploy: obj/Books
	scp obj/Books iphone:/Applications/Books.app/
	#ssh iphone chmod +x /Applications/Books.app/Books

deploy-app: bundle
	scp -r Books.app root@iphone:/Applications/
	ln -f -s '~/Library/Books/Default.png' Books.app/Default.png
	ssh root@iphone ln -f -s '/var/mobile/Library/Books/Default.png' /Applications/Books.app/Default.png

package: bundle
	zip -y -r9 $(ARCHIVE) Books.app
	
deploy-repo: package repo.xml
	scp $(ARCHIVE) $(SCP_BASE)
	scp repo.xml $(SCP_BASE)

# The nightly build builds the ZIP and repo XML, then places them both in a known location
# where the build server will find them to deploy to the site.
# The lock file ensure that the deployment job won't try to move files that are half copied.
nightly: package repo.xml
	mkdir -p $(NIGHTLY_PICKUP)
	touch $(NIGHTLY_PICKUP)/lock-file
	cp repo.xml $(NIGHTLY_PICKUP)
	cp repo.xml.gz $(NIGHTLY_PICKUP)
	cp Books-*.zip $(NIGHTLY_PICKUP)
	chmod g+w $(NIGHTLY_PICKUP)/*
	rm $(NIGHTLY_PICKUP)/lock-file
	
