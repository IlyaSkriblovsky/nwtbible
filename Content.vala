public struct Location
{
    public Book book;
    public int chapter;
    public int verse;

    public Location.invalid()
    {
        book = null;
        chapter = verse = 0;
    }

    public Location(Book book, int chapter, int verse)
    {
        this.book = book;
        this.chapter = chapter;
        this.verse = verse;
    }

    public bool valid()
    {
        return book != null  &&  1 <= chapter  &&  chapter <= book.chapter_count  &&
            1 <= verse  &&  verse <= book.verse_count[chapter-1];
    }

    public string to_string()
    {
        if (valid())
            return book.name() + " " + chapter.to_string() + ":" + verse.to_string();
        else
            return "<invalid loc>";
    }

    public string to_string_without_verse()
    {
        if (valid())
            return book.name() + " " + chapter.to_string();
        else
            return "<invalid loc>";
    }

    public Location? prev_chapter()
    {
        if (! valid())
            return null;

        Location prev = Location.invalid();
        prev.verse = 1;

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

    public Location? next_chapter()
    {
        if (! valid())
            return null;

        Location next = Location.invalid();
        next.verse = 1;

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


public class Book
{
    public string code { get; private set; }
    public int number { get; private set; }
    public int chapter_count { get; private set; }
    public int[] verse_count { get; private set; }

    private HashTable<Language,string> names = new HashTable<Language,string>(null, null);

    public Book(string code, int number, KeyFile key_file)
        throws KeyFileError
    {
        this.code = code;
        this.number = number;

        var verses = key_file.get_integer_list(code, "verses");
        chapter_count = verses.length;
        verse_count = verses;

        foreach (var key in key_file.get_keys(code))
            if (key.has_prefix("name_"))
            {
                var langcode = key.substring(5);
                var lang = Languages.instance.langByCode(langcode);
                if (lang == null)
                    stderr.printf("NO SUCH LANG: %s\n", langcode);
                else
                    names.replace(lang, key_file.get_string(code, key));
            }
    }

    public string name(Language? lang = null)
    {
        if (lang == null)
            lang = Languages.instance.current;

        return names.lookup(lang);
    }
}


public class Books
{
    private static Books _instance = null;
    public static Books instance
    {
        get
        {
            if (_instance == null)
                _instance = new Books();
            return _instance;
        }
    }


    private KeyFile books_file;

    private List<Book> _books = new List<Book>();
    public List<unowned Book> books { get { return _books; } }

    HashTable<string, unowned Book> _book_by_code = new HashTable<string, unowned Book>((HashFunc)string.hash, str_equal);

    public Books()
    {
        books_file = new KeyFile();

        try
        {
            books_file.load_from_file(Paths.books_ini(), KeyFileFlags.NONE);

            int booknumber = 1;
            foreach (var bookcode in books_file.get_groups())
            {
                var book = new Book(bookcode, booknumber++, books_file);
                _books.append(book);
                _book_by_code.insert(bookcode, book);
            }
        }
        catch (FileError e)
        {
            stderr.printf("FileError: %s\n", e.message);
        }
        catch (KeyFileError e)
        {
            stderr.printf("KeyFileError: %s\n", e.message);
        }
    }


    public unowned Book? book_by_code(string code)
    {
        return _book_by_code.lookup(code);
    }
}
