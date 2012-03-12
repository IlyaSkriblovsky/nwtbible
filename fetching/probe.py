f = file("langs.txt", "r")

langs = []

prev = None
flag = False
for line in f:
    if not flag: prev = line
    else:
        langs.append((prev.strip(), line.strip()))
    flag = not flag



good = []
strange = []

import re
import urllib

for (name, code) in langs:
    print code

    index = urllib.urlopen('http://watchtower.org/' + code + '/')
    if index.getcode() == 200:
        content = index.read()
        begin = content.find('<div class="bible">')
        if begin != -1:
            found = re.search(r'<div class="bible">.*?<h2><a href="(.*?)">', content, re.DOTALL)
            if found == None:
                print "STRANGE:", code
                strange.append(code)
            else:
                print "GOOD:", code, found.group(1)
                good.append((code, found.group(1)))


print "==================="
for (code, url) in good:
    print code, url

print "total: {0}".format(len(good))

print "\n================="
print "Strange:",
print strange
