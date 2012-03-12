import ConfigParser
import urllib
import re

langconfig = ConfigParser.RawConfigParser()
langconfig.read("langs.ini")

config = ConfigParser.RawConfigParser()
config.read("books.ini")

#for book in config.sections():
for book in ['ps']:
    size = None

    for (namelang, name) in config.items(book):
        lang = namelang[5:]
        url = langconfig.get(lang, 'bibleurl')
        req = urllib.urlopen('http://watchtower.org' + url + book + '/chapters.htm')
        if req.getcode() != 200:
            print "BAD:", book, lang, name

        chapters = re.findall(r'chapter_\d\d\d\.htm', req.read())
        print lang, "len = ", len(chapters)
        if size == None:
            size = len(chapters)

        if len(chapters) != size:
            print "STRANGE!", book, lang, name
            print "size = ", size
            print "len(chapters) = ", len(chapters)

    print "LEN OF", book, "IS", size
