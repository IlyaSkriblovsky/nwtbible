import urllib

for line in file('good.txt'):
    (code, url) = line.strip().split(' ')

    a = urllib.urlopen('http://watchtower.org' + url + 'ge/chapter_001.htm')
    b = urllib.urlopen('http://watchtower.org' + url + 're/chapter_022.htm')

    print code,
    if a.getcode() == 200 and b.getcode() == 200:
        print "OK"
    else:
        print "BAD: {0} {1}".format(a.getcode(), b.getcode())
