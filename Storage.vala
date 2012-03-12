public class Storage
{
    Sqlite.Database db;
    Sqlite.Statement insert;
    Sqlite.Statement select;
    Sqlite.Statement select_count;
    Sqlite.Statement clear;

    public Storage()
    {
        var file = Paths.user_dir() + "cache.sqlite";
        Sqlite.Database.open(file, out db);

        if (db == null)
        {
            var note = new Hildon.Note.information((Gtk.Window)null, "Cannot open cache database!");
            note.run();
            note.destroy();
        }

        db.exec("CREATE TABLE IF NOT EXISTS html (lang, book, booknumber, chapter, html, PRIMARY KEY (lang, booknumber, chapter));");

        db.prepare_v2(
            "REPLACE INTO html (lang, book, booknumber, chapter, html) VALUES (?, ?, ?, ?, ?);",
            -1, out insert
        );
        db.prepare_v2(
            "SELECT html FROM html WHERE lang=? AND booknumber=? AND chapter=?;",
            -1, out select
        );
        db.prepare_v2(
            "SELECT count(*) FROM html WHERE lang=? AND booknumber=? AND chapter=?;",
            -1, out select_count
        );

        db.prepare_v2(
            "DELETE FROM html;",
            -1, out clear
        );
    }


    public signal void found_new_chapter(Chapter chapter);
    public signal void search_finished();

    private string text_to_search;

    public void search_in_thread(string text)
    {
        text_to_search = text;

        try
        {
            Thread.create(_search_in_thread, true);
        }
        catch (ThreadError e)
        {
            stderr.printf("ThreadError: %s\n", e.message);
        }
    }

    class FoundChapter
    {
        public Storage storage;
        public Chapter chapter;

        public FoundChapter(Storage storage, Chapter chapter)
        {
            this.storage = storage;
            this.chapter = chapter;
        }

        public bool fire()
        {
            storage.found_new_chapter(chapter);
            return false;
        }
    }

    public void* _search_in_thread()
    {
        var text = text_to_search;

        Sqlite.Database qdb;

        var file = Paths.user_dir() + "cache.sqlite";
        Sqlite.Database.open(file, out qdb);

        if (qdb == null)
            stderr.printf("qdb == null\n");

        NWTBible.install_unicode_like(qdb);

        Sqlite.Statement qstmt;
        qdb.prepare_v2(
            "SELECT lang, book, chapter FROM html WHERE lang = ? AND html LIKE ? ORDER BY booknumber, chapter;",
            -1, out qstmt
        );

        qstmt.reset();
        qstmt.bind_text(1, Languages.instance.current.code);
        qstmt.bind_text(2, text);

        while (qstmt.step() == Sqlite.ROW)
        {
            var found = new FoundChapter(this, Chapter(
                Books.instance.book_by_code(qstmt.column_text(1)),
                qstmt.column_int(2)
            ));

            Idle.add(found.fire);
        }

        Idle.add(() => { search_finished(); return false; });

        return null;
    }

    public void cache_chapter(Chapter chapter, string contents, Language? language = null)
    {
        if (language == null)
            language = Languages.instance.current;

        insert.reset();
        insert.bind_text(1, language.code);
        insert.bind_text(2, chapter.book.code);
        insert.bind_int (3, chapter.book.number);
        insert.bind_int (4, chapter.chapter);
        insert.bind_text(5, contents);
        insert.step();
    }


    public bool has_cached_chapter(Chapter chapter, Language? language = null)
    {
        if (language == null)
            language = Languages.instance.current;

        select_count.reset();
        select_count.bind_text(1, language.code);
        select_count.bind_int (2, chapter.book.number);
        select_count.bind_int (3, chapter.chapter);

        if (select_count.step() == Sqlite.ROW)
            return select_count.column_int(0) == 1;
        else
        {
            return false;
        }
    }


    public string? load_cached_chapter(Chapter chapter, Language? language = null)
    {
        if (language == null)
            language = Languages.instance.current;

        select.reset();
        select.bind_text(1, language.code);
        select.bind_int (2, chapter.book.number);
        select.bind_int (3, chapter.chapter);

        if (select.step() == Sqlite.ROW)
        {
            return select.column_text(0);
        }
        else
            return null;
    }


    public void clear_cache()
    {
        clear.reset();
        clear.step();
    }
}
