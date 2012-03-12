ifdef DEBUG
	VALA_FLAGS := $(VALA_FLAGS) -g -D DEBUG
endif



SOURCES=Main.vala               \
        Language.vala           \
        LangButton.vala         \
        Content.vala            \
        VerseSelector.vala      \
        MainWindow.vala         \
        Fetcher.vala            \
        Paths.vala              \
        nwtbible-ext.c          \
        he-fullscreen-button.c  \
        VerseSet.vala           \
        Bookmarks.vala          \
        Storage.vala            \
        Settings.vala           \
        FindWindow.vala

PKGS = hildon-1         \
       webkit-1.0       \
       libsoup-2.4      \
       libxml-2.0       \
       x11              \
       nwtbible-misc    \
       nwtbible-ext     \
       sqlite3

SHAREFILES = langs.ini  \
             books.ini  \
             script.js  \
             style.css  \
             welcome.html

EXTLIBS = icutu

all: nwtbible

nwtbible: $(SOURCES)
	valac $(VALA_FLAGS) --thread --vapidir . --Xcc=-I. $(PKGS:%=--pkg %) $(EXTLIBS:%=--Xcc=-l%) -o $@ $(SOURCES)

clean:
	rm -rf nwtbible *.vala.c


install: nwtbible $(SHAREFILES) nwtbible.png nwtbible.desktop
	cp nwtbible $(DESTDIR)/usr/bin/
	cp $(SHAREFILES) $(DESTDIR)/usr/share/nwtbible/
	cp nwtbible.png $(DESTDIR)/usr/share/icons/hicolor/48x48/apps/
	cp nwtbible.desktop $(DESTDIR)/usr/share/applications/hildon/
