public struct Chapter
{
    public Book book { get; set; }
    public int chapter { get; set; }

    public Chapter(Book book, int chapter)
    {
        this.book = book;
        this.chapter = chapter;
    }

    public Chapter.invalid()
    {
        this.book = null;
        this.chapter = 0;
    }

    public bool valid()
    {
        return book != null && 1 <= chapter && chapter <= book.chapter_count;
    }

    public string to_string()
    {
        if (valid())
            return "%s %d".printf(book.name(), chapter);
        else
            return "<invalid>";
    }



    public Chapter? prev()
    {
        if (! valid())
            return null;

        Chapter prev = Chapter.invalid();

        if (chapter > 1)
        {
            prev.book = book;
            prev.chapter = chapter - 1;
            return prev;
        }
        else
        {
            unowned List<Book> prev_list_pos = Books.instance.books.find(book).prev;
            if (prev_list_pos != null)
            {
                prev.book = prev_list_pos.data;
                prev.chapter = prev.book.chapter_count;
                return prev;
            }
            else
                return null;
        }
    }

    public Chapter? next()
    {
        if (! valid())
            return null;

        Chapter next = Chapter.invalid();

        if (chapter < book.chapter_count)
        {
            next.book = book;
            next.chapter = chapter + 1;
            return next;
        }
        else
        {
            unowned List<Book> next_list_pos = Books.instance.books.find(book).next;
            if (next_list_pos != null)
            {
                next.book = next_list_pos.data;
                next.chapter = 1;
                return next;
            }
            else
                return null;
        }
    }
}



public struct VerseSet
{
    public Chapter chapter;

    public int[] verses;

    public VerseSet(Chapter chapter, int[] verses)
    {
        this.chapter = chapter;
        this.verses = verses;
    }

    public VerseSet.from_location(Location location)
    {
        this.chapter = Chapter(location.book, location.chapter);
        this.verses = { location.verse };
    }

    public VerseSet.invalid()
    {
        this.chapter = Chapter.invalid();
        this.verses = {};
    }


    public bool valid()
    {
        return chapter.valid();
    }

    public bool empty()
    {
        return verses.length == 0;
    }


    public void set_verses(int[] verses)
    {
        this.verses = verses;
    }


    public string to_string()
    {
        if (! valid())
            return "<invalid>";

        string str = chapter.to_string();

        if (verses.length > 0)
        {
            str += ":";

            int state = 0;
            int prev = 0;
            foreach (var v in verses)
            {
                if (prev == 0)
                    str += "%d".printf(v);
                else if (v == prev + 1)
                    state = 1;
                else if (state == 1)
                {
                    str += "‒%d,%d".printf(prev, v);
                    state = 0;
                }
                else
                    str += ",%d".printf(v);


                prev = v;
            }

            if (state == 1)
                str += "‒%d".printf(prev);
        }

        return str;
    }

    public string js_list()
    {
        if (! valid()) return "[]";

        var s = "[";

        var flag = false;
        foreach (var v in verses)
        {
            if (flag)
                s += ",";
            else
                flag = true;

            s += "%d".printf(v);
        }

        return s + "]";
    }


    public void clear_verses()
    {
        verses = {};
    }

    public static int compare(VerseSet v1, VerseSet v2)
    {
        if (! v1.valid())
            if (! v2.valid()) return 0;
            else return -1;
        else if (! v2.valid()) return +1;

        if (v1.chapter.book.number < v2.chapter.book.number)
            return -1;
        else if (v1.chapter.book.number > v2.chapter.book.number)
            return +1;

        if (v1.chapter.chapter < v2.chapter.chapter)
            return -1;
        else if (v1.chapter.chapter > v2.chapter.chapter)
            return +1;

        if (v1.empty())
            if (v2.empty()) return 0;
            else return -1;
        else if (v2.empty()) return +1;

        if (v1.verses[0] < v2.verses[0])
            return -1;
        else if (v1.verses[0] > v2.verses[0])
            return +1;

        return 0;
    }
}
