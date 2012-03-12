import urllib
import re

for lang in file("good.txt"):
    (name, selfname, code, url) = lang.strip().split(',')

    page = urllib.urlopen("http://watchtower.org" + url + "index.htm")
#    if page.getcode() != 200:
#        print "FAIL:", code
#    else:
    chaps = re.findall(r'\b([a-z0-9]+)/chapter(?:s|_\d\d\d).htm">([^<]*)</?a', page.read())
    if len(chaps) != 66:
        print "INVALID CHAPS #:", code

    out = file("chaps/" + code, "w")
    for (chap, name) in chaps:
        name = name.replace("&nbsp;", " ").strip()
        out.write(chap + "=" + name + "\n")
    print "OK:", code
