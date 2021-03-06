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

SOURCES=$(wildcard source/AGRegex/*.c source/AGRegex/*.m source/palm/*.c source/palm/*.m source/*.c source/*.m)
OBJECTS=$(patsubst source/%,obj/%,$(patsubst source/palm/%,obj/%,$(patsubst source/AGRegex/%,obj/%, \
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES))) \
	$(patsubst %.cpp,%.o,$(filter %.cpp,$(SOURCES)))) \
))

# Override this on the command line for nightly builds.
REPOTAG=Repository in Exile

IMAGES=$(wildcard images/*.png)

ARCHIVE=Books-$(VERSION).zip

BASEURL=http://www.thebedells.org/books/
SCP_BASE=www:~/wwwroot/books/
NIGHTLY_PICKUP=/tmp/Books-nightly

QUIET=true

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
	
obj/%.o:    source/AGRegex/%.m 
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $< > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

obj/%.o:    source/AGRegex/%.c
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $< > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

htmltest: test/HTMLFixerTester.m source/HTMLFixer.m
	gcc -DDESKTOP=1 -framework CoreFoundation -framework AppKit -framework Cocoa -lobjc test/HTMLFixerTester.m source/AGRegex/*.c source/AGRegex/*.m source/HTMLFixer.m -o test/htmltest

ht:	htmltest
	./test/htmltest test/in.html test/out.html

clean:
	rm -rf obj Books.app Books-*.tbz Books-*.zip repo.xml repo.xml.gz
	cd jpeg-6b ; if [ -f Makefile ] ; then make distclean ; fi


obj/Info.plist: Info.plist.tmpl version
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
	
deploy: obj/Books
	scp obj/Books iphone:/Applications/Books.app/
	#ssh iphone chmod +x /Applications/Books.app/Books

deploy-app: bundle
	scp -r Books.app root@iphone:/Applications/

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
	
jpeg-6b/.libs/libjpeg.a:	jpeg-6b/*.c jpeg-6b/*.h
	cd jpeg-6b ; \
		AR=arm-apple-darwin-ar AR2=arm-apple-darwin-ranlib CC=arm-apple-darwin-gcc \
		./configure --prefix=$(HEAVENLY)/usr/local \
		--build=i386-apple-darwin --host=arm-apple-darwin --enable-static --enable-shared ; \
		make AR="arm-apple-darwin-ar rc" AR2="arm-apple-darwin-ranlib" libjpeg.la
	
.PHONY: nightly deploy-repo package deploy-app deploy clean bundle test all version
