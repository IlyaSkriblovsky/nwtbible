import urllib
import re
import ConfigParser


config = ConfigParser.RawConfigParser()
config.read("books.ini")

for book in config.sections():
    chapters = int(config.get(book, 'chapters'))
    versecounts = []
    for chap in range(1, chapters+1):
        page = urllib.urlopen('http://watchtower.org/e/bible/{0}/chapter_{1:03}.htm'.format(book, chap))
        if page.getcode() != 200:
            print "ERROR:", book, chap
        else:
            contents = page.read()
            verses = re.findall(r'a name="bk', contents)
            #print book, chap, len(verses)
            versecounts.append(len(verses))

    print book, ','.join([str(x) for x in versecounts])
