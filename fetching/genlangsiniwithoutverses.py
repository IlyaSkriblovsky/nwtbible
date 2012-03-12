import glob
import os

booksInOrder = []
books = {}

for chapfile in glob.glob('chaps/*'):
    langcode = os.path.basename(chapfile)

    content = file(chapfile).read().split('\n')
    for book in content:
        if len(book) == 0: continue
        bookcode, bookname = book.split('=')

        try:
            books[bookcode][langcode] = bookname
        except KeyError:
            books[bookcode] = { langcode: bookname }
            booksInOrder.append(bookcode)


for bookcode in booksInOrder:
    print '[%s]' % bookcode
    sortedLangs = books[bookcode].keys()
    sortedLangs.sort()
    for langcode in sortedLangs:
        print '%s=%s' % (langcode, books[bookcode][langcode])
    print
