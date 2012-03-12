public class Bookmark: Object
{
    public VerseSet verse_set;
    public string description;
    public int time_created;

    public Bookmark(VerseSet verse_set, string description, int time_created = 0)
    {
        this.verse_set = verse_set;
        this.description = description;

        if (time_created > 0)
            this.time_created = time_created;
        else
            this.time_created = (int)time_t();
    }



    public static int compare_time_created(Bookmark b1, Bookmark b2)
    {
        if (b1.time_created < b2.time_created) return -1;
        else if (b1.time_created > b2.time_created) return +1;
        else return 0;
    }

    public static int compare_verse(Bookmark b1, Bookmark b2)
    {
        return VerseSet.compare(b1.verse_set, b2.verse_set);
    }

    public static int compare_description(Bookmark b1, Bookmark b2)
    {
        var down1 = b1.description.down();
        var down2 = b2.description.down();

        if (down1 < down2) return -1;
        else if (down1 > down2) return +1;
        else return 0;
    }
}

public class Bookmarks
{
    public List<Bookmark> _bookmarks;
    public List<unowned Bookmark> bookmarks { get { return _bookmarks; } }

    public string filename;


    public Bookmarks(string filename)
    {
        this.filename = filename;

        var key_file = new KeyFile();

        try
        {
            key_file.load_from_file(filename, KeyFileFlags.NONE);

            foreach (var group in key_file.get_groups())
            {
                var description = key_file.get_string(group, "description");
                var book = Books.instance.book_by_code(key_file.get_string(group, "book"));
                var chapter = key_file.get_integer(group, "chapter");

                int time_created = 0;
                try { time_created = key_file.get_integer(group, "time_created"); } catch (KeyFileError e) { }

                int[] verses;

                try
                {
                    verses = key_file.get_integer_list(group, "verses");
                }
                catch (KeyFileError e)
                {
                    verses = {};
                }

                _bookmarks.append(new Bookmark(
                    VerseSet(
                        Chapter(
                            book,
                            chapter
                        ),
                        verses
                    ),
                    description,
                    time_created
                ));
            }
        }
        catch (KeyFileError e)
        {
            stderr.printf("Bookmarks: KeyFileError: %s\n", e.message);
        }
        catch (FileError e)
        {
            stderr.printf("Bookmarks: FileError: %s\n", e.message);
        }
    }

    ~Bookmarks()
    {
        save();
    }

    public void append(Bookmark bookmark)
    {
        _bookmarks.append(bookmark);
    }

    public void remove(Bookmark bookmark)
    {
        _bookmarks.remove(bookmark);
    }


    public void save()
    {
        var key_file = new KeyFile();

        var number = 1;
        foreach (var bookmark in _bookmarks)
        {
            var group = "%d".printf(number);
            key_file.set_string(group, "book", bookmark.verse_set.chapter.book.code);
            key_file.set_integer(group, "chapter", bookmark.verse_set.chapter.chapter);
            key_file.set_integer_list(group, "verses", bookmark.verse_set.verses);
            key_file.set_string(group, "description", bookmark.description);
            key_file.set_integer(group, "time_created", bookmark.time_created);

            number++;
        }

        try
        {
            FileUtils.set_contents(
                filename,
                key_file.to_data()
            );
        }
        catch (FileError e)
        {
            stderr.printf("Bookmarks: FileError: %s\n", e.message);
        }
    }
}



public class BookmarksWindow: Hildon.StackableWindow
{
    Gtk.ListStore store;

    Hildon.EditToolbar edit_toolbar;

    Gtk.TreeView view;


    Bookmarks bookmarks;


    Gtk.ToggleButton sort_time_button;
    Gtk.ToggleButton sort_verse_button;
    Gtk.ToggleButton sort_description_button;


    public signal void bookmark_selected(Bookmark bookmark);


    private BookmarksSortType _sort_type;
    public BookmarksSortType sort_type
    {
        get { return _sort_type; }
        set
        {
            _sort_type = value;

            sort_time_button.active = _sort_type == BookmarksSortType.BY_TIME;
            sort_verse_button.active = _sort_type == BookmarksSortType.BY_VERSE;
            sort_description_button.active = _sort_type == BookmarksSortType.BY_DESCRIPTION;

            switch (_sort_type)
            {
                case BookmarksSortType.BY_TIME: store.set_sort_func(2, cmp_by_time); break;
                case BookmarksSortType.BY_VERSE: store.set_sort_func(2, cmp_by_verse); break;
                case BookmarksSortType.BY_DESCRIPTION: store.set_sort_func(2, cmp_by_description); break;
                default: store.set_sort_func(2, cmp_by_time); break;
            }
            store.set_sort_column_id(2, Gtk.SortType.ASCENDING);
        }
    }


    public BookmarksWindow()
    {
        title = "Bookmarks";

        store = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Bookmark));

//        view = new Gtk.TreeView.with_model(store);
        view = (Gtk.TreeView)Hildon.gtk_tree_view_new_with_model(Hildon.UIMode.NORMAL, store);

        var location_renderer = new Gtk.CellRendererText();
        // location_renderer.style = Pango.Style.ITALIC;
        location_renderer.weight = 800;
        view.insert_column_with_attributes(
            -1, "Location",
            location_renderer,
            "text", 0
        );
        view.row_activated.connect(on_row_activated);

        var description_renderer = new Gtk.CellRendererText();
        description_renderer.ellipsize = Pango.EllipsizeMode.END;
        view.insert_column_with_attributes(
            -1, "Description",
            description_renderer,
            "text", 1
        );

        var scroll = new Hildon.PannableArea();
        scroll.add(view);

        add(scroll);

        scroll.show_all();


        var app_menu = new Hildon.AppMenu();

        var delete_button = new Hildon.Button.with_text(
            Hildon.SizeType.AUTO,
            Hildon.ButtonArrangement.HORIZONTAL,
            "Delete",
            ""
        );
        delete_button.clicked.connect(on_delete_button_clicked);
        app_menu.append(delete_button);


        sort_time_button = Hildon.gtk_toggle_button_new(Hildon.SizeType.AUTO) as Gtk.ToggleButton;
        sort_time_button.set_label("By time");
        sort_verse_button = Hildon.gtk_toggle_button_new(Hildon.SizeType.AUTO) as Gtk.ToggleButton;
        sort_verse_button.set_label("By verse");
        sort_description_button = Hildon.gtk_toggle_button_new(Hildon.SizeType.AUTO) as Gtk.ToggleButton;
        sort_description_button.set_label("By descr.");

        sort_time_button.toggled.connect(() => { if (sort_time_button.active) sort_type = BookmarksSortType.BY_TIME; });
        sort_verse_button.toggled.connect(() => { if (sort_verse_button.active) sort_type = BookmarksSortType.BY_VERSE; });
        sort_description_button.toggled.connect(() => { if (sort_description_button.active) sort_type = BookmarksSortType.BY_DESCRIPTION; });

        app_menu.add_filter((Gtk.Button) new Gtk.Label("Sort by:"));
        app_menu.add_filter(sort_time_button);
        app_menu.add_filter(sort_verse_button);
        app_menu.add_filter(sort_description_button);


        app_menu.show_all();
        set_app_menu(app_menu);


        edit_toolbar = new Hildon.EditToolbar.with_text("Select bookmarks to delete", "Delete");
        edit_toolbar.button_clicked.connect(on_edit_toolbar_button_clicked);
        edit_toolbar.arrow_clicked.connect(on_edit_toolbar_arrow_clicked);
        set_edit_toolbar(edit_toolbar);
    }


    private static int cmp_by_verse(Gtk.TreeModel model, Gtk.TreeIter ai, Gtk.TreeIter bi)
    {
        unowned Bookmark a;
        unowned Bookmark b;
        model.@get(ai, 2, out a);
        model.@get(bi, 2, out b);

        return Bookmark.compare_verse(a, b);
    }

    private static int cmp_by_time(Gtk.TreeModel model, Gtk.TreeIter ai, Gtk.TreeIter bi)
    {
        unowned Bookmark a;
        unowned Bookmark b;
        model.@get(ai, 2, out a);
        model.@get(bi, 2, out b);

        return Bookmark.compare_time_created(a, b);
    }

    private static int cmp_by_description(Gtk.TreeModel model, Gtk.TreeIter ai, Gtk.TreeIter bi)
    {
        unowned Bookmark a;
        unowned Bookmark b;
        model.@get(ai, 2, out a);
        model.@get(bi, 2, out b);

        return Bookmark.compare_description(a, b);
    }


    public void fill(Bookmarks bookmarks)
    {
        this.bookmarks = bookmarks;

        store.clear();

        Gtk.TreeIter iter;
        foreach (var bookmark in bookmarks.bookmarks)
        {
            store.append(out iter);
            store.set(iter,
                0, bookmark.verse_set.to_string(),
                1, bookmark.description,
                2, bookmark
            );
        }
    }


    private void on_row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column)
    {
        Gtk.TreeIter iter;
        store.get_iter(out iter, path);

        unowned Bookmark bookmark;
        store.@get(iter, 2, out bookmark);

        bookmark_selected(bookmark);
    }


    void on_delete_button_clicked()
    {
        view.row_activated.disconnect(on_row_activated);

        Hildon.gtk_tree_view_set_ui_mode(view, Hildon.UIMode.EDIT);
        view.get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);
        view.get_selection().unselect_all();

        edit_toolbar.show();
        fullscreen();
    }


    void on_edit_toolbar_button_clicked()
    {
        view.get_selection().selected_foreach((model, path, iter) => {
            unowned Bookmark bookmark;
            store.@get(iter, 2, out bookmark);

            bookmarks.remove(bookmark);
        });

        fill(bookmarks);

        on_edit_toolbar_arrow_clicked();
    }

    void on_edit_toolbar_arrow_clicked()
    {
        view.row_activated.connect(on_row_activated);

        Hildon.gtk_tree_view_set_ui_mode(view, Hildon.UIMode.NORMAL);
        view.get_selection().set_mode(Gtk.SelectionMode.SINGLE);

        edit_toolbar.hide();
        unfullscreen();
    }
}
