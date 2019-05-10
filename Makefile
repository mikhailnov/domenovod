PREFIX = /usr
BINDIR = $(PREFIX)/bin

all:
	echo "Nothing to do, use make install"
install:
	mkdir -p $(DESTDIR)/$(BINDIR)
	install -m 0755 ./domenovod.sh $(DESTDIR)/$(BINDIR)/domenovod
