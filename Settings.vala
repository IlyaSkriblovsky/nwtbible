public enum BookmarksSortType
{
    BY_TIME,
    BY_VERSE,
    BY_DESCRIPTION
}


public class NWTSettings
{
    KeyFile key_file;

    public NWTSettings()
    {
        key_file = new KeyFile();

        try
        {
            key_file.load_from_file(Paths.user_dir() + "settings.ini", KeyFileFlags.NONE);
        }
        catch (FileError e)
        {
            stderr.printf("Settings: FileError: %s\n", e.message);
        }
        catch (KeyFileError e)
        {
            stderr.printf("Settings: KeyFileError: %s\n", e.message);
        }
    }

    ~NWTSettings()
    {
        FileUtils.set_contents(
            Paths.user_dir() + "settings.ini",
            key_file.to_data()
        );
    }


    public void set_zoom(double zoom)
    {
        key_file.set_double("view", "zoom", zoom);
    }

    public double get_zoom()
    {
        try
        {
            return key_file.get_double("view", "zoom");
        }
        catch (KeyFileError e)
        {
            return 1.0;
        }
    }


    public void set_chapter(Chapter chapter)
    {
        if (chapter.valid())
        {
            key_file.set_string("location", "book", chapter.book.code);
            key_file.set_integer("location", "chapter", chapter.chapter);
        }
    }

    public Chapter get_chapter()
    {
        var chapter = Chapter.invalid();

        try
        {
            var book_code = key_file.get_string("location", "book");
            foreach (var book in Books.instance.books)
                if (book.code == book_code)
                    chapter.book = book;

            chapter.chapter = key_file.get_integer("location", "chapter");
        }
        catch (KeyFileError e)
        {
        }

        return chapter;
    }



    public void set_scroll(int scroll)
    {
        key_file.set_integer("view", "scroll", scroll);
    }

    public int get_scroll()
    {
        try
        {
            return key_file.get_integer("view", "scroll");
        }
        catch (KeyFileError e)
        {
            return 0;
        }
    }


    public void set_language(Language language)
    {
        key_file.set_string("language", "language", language.code);
    }

    public Language? get_language()
    {
        try
        {
            return Languages.instance.langByCode(key_file.get_string("language", "language"));
        }
        catch (KeyFileError e)
        {
            return null;
        }
    }


    public void set_find_notice_shown(bool shown)
    {
        key_file.set_boolean("messages", "find_notice_shown", shown);
    }

    public bool get_find_notice_shown()
    {
        try
        {
            return key_file.get_boolean("messages", "find_notice_shown");
        }
        catch (KeyFileError e)
        {
            return false;
        }
    }


    public void set_swipe_notice_shown(bool shown)
    {
        key_file.set_boolean("messages", "swipe_notice_shown", shown);
    }

    public bool get_swipe_notice_shown()
    {
        try
        {
            return key_file.get_boolean("messages", "swipe_notice_shown");
        }
        catch (KeyFileError e)
        {
            return false;
        }
    }



    public BookmarksSortType get_bookmarks_sort_type()
    {
        try
        {
            var i = key_file.get_integer("bookmarks", "sort_by");
            switch (i)
            {
                case 0: return BookmarksSortType.BY_TIME;
                case 1: return BookmarksSortType.BY_VERSE;
                case 2: return BookmarksSortType.BY_DESCRIPTION;
                default: return BookmarksSortType.BY_TIME;
            }
        }
        catch (KeyFileError e)
        {
            return BookmarksSortType.BY_TIME;
        }
    }


    public void set_bookmarks_sort_type(BookmarksSortType sort_type)
    {
        int i;
        switch (sort_type)
        {
            case BookmarksSortType.BY_TIME: i = 0; break;
            case BookmarksSortType.BY_VERSE: i = 1; break;
            case BookmarksSortType.BY_DESCRIPTION: i = 2; break;
            default: i = 0; break;
        }

        key_file.set_integer("bookmarks", "sort_by", i);
    }
}
