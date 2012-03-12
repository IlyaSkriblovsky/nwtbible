import sqlite3
conn = sqlite3.connect('nwt.sqlite')
c = conn.cursor()
c.execute('CREATE TABLE langs (id VARCHAR PRIMARY KEY, engname, selfname, bibleurl)')

for line in filter(lambda l: len(l) > 0, file('good.txt').read().split('\n')):
    p = line.split(',')
    c.execute('INSERT INTO langs VALUES (?, ?, ?, ?)', (
        p[2], p[0], p[1], p[3]
    ))

conn.commit()

c.execute('CREATE TABLE books (code VARCHAR PRIMARY KEY, no INTEGER)')
c.execute('CREATE INDEX no ON books (no)')

c.execute('CREATE TABLE booknames (lang, book, name)')
c.execute('CREATE INDEX book__lang ON booknames (book, lang)')

c.execute('CREATE TABLE chapters (book, chapter, versecount)')
c.execute('CREATE INDEX book__chapter ON chapters (book, chapter)')

bookNo = 1
for line in filter(lambda l: len(l) > 0, file('../books.ini').read().split('\n')):
    if line[0] == '[':
        curbook = line[1:-1]
        c.execute('INSERT INTO books VALUES (?, ?)', (curbook, bookNo))
        bookNo += 1
    elif line[0:7] == 'verses=':
        import itertools
        versecounts = line[7:].split(';')
        for chapNo, versecount in itertools.izip(itertools.count(1), versecounts):
            c.execute('INSERT INTO chapters VALUES (?, ?, ?)', (
                chapNo, curbook, versecount
            ))

conn.commit()

import glob, os
for chapfile in glob.glob('chaps/*'):
    langcode = os.path.basename(chapfile)
    for line in filter(lambda l: len(l)>0, file(chapfile).read().split('\n')):
        c.execute('INSERT INTO booknames VALUES (?, ?, ?)', (
            line.split('=')[0],
            langcode,
            line.split('=')[1]
        ))

conn.commit()
