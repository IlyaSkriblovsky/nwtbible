var zoom = 1

var highlighted = []


function on_chapter_loaded(verse_list, zoom)
{
    set_zoom(zoom)

    if (verse_list.length > 0)
        scrollTo(0, num(verse_list[0]).offsetTop - 50)

    set_highlighted(verse_list)

    enable_selecting(true)

    scroll_to_found()
}


function on_body_click()
{
    var verse = verse_from_element(event.srcElement)

    if (verse == null)
        return;

    if (highlighted[verse])
        unhighlight_verse(verse)
    else
        highlight_verse(verse)
}


function verse_from_element(element)
{
    while (element != null)
    {
        if (element.id != null && element.id.substring(0, 2) == "vs")
            return parseInt(element.id.substring(2))

        element = element.parentNode
    }

    return null
}

function set_zoom(value)
{
    zoom = parseFloat(value)

    var i = 1
    var vs
    while (true)
    {
        vs = document.getElementById('vs' + i)
        if (vs == null)
            break

        if (vs.offsetTop >= scrollY)
            break

        i++
    }

    var offset = vs.offsetTop - scrollY

    document.getElementsByTagName("body")[0].style.fontSize = parseInt(zoom * 26) + 'px'

    scrollTo(0, vs.offsetTop - offset)
}

function num(verse)
{
    return document.getElementsByName('bk' + verse)[0]
}

function spans(verse)
{
    var main = document.getElementById('vs' + verse)
    if (main == null)
        return []

    var ss = [ main ]

    var cont
    var contN = 2
    do
    {
        cont = document.getElementById('vs' + verse + '-' + contN++)
        if (cont)
            ss.push(cont)
    } while (cont != null)

    return ss
}

function highlight_verse(verse)
{
    highlighted[verse] = true

    var a = num(verse)
    a.style.color = 'red'

    var ss = spans(verse)
    for (var i in ss)
        ss[i].style.background = "#ffff90"
}

function unhighlight_verse(verse)
{
    delete highlighted[verse]

    var a = num(verse)
    a.style.color = null

    var ss = spans(verse)
    for (var i in ss)
        ss[i].style.background = null
}

function enable_selecting(enable)
{
    if (enable)
        document.body.onclick = on_body_click
    else
        document.body.onclick = null
}

function get_highlighted()
{
    var list = []
    for (var verse in highlighted)
        list.push(verse)

    return list
}

function set_highlighted(list)
{
    for (var verse in highlighted)
        unhighlight_verse(verse)

    for (var i in list)
        highlight_verse(list[i])
}


function get_scroll()
{
    return scrollY
}

function set_scroll(scroll)
{
    scrollTo(0, scroll)
}



function scroll_to_found()
{
    var found = document.getElementsByName('found')
    if (found.length > 0)
        scrollTo(0, found[0].offsetTop - 40)
}
