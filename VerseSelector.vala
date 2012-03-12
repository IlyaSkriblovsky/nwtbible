public class VerseSelector: Gtk.Dialog
{
    Gtk.ListStore book_store = new Gtk.ListStore(1, typeof(string));
    Gtk.ListStore chapter_store = new Gtk.ListStore(1, typeof(string));
    Gtk.ListStore verse_store = new Gtk.ListStore(1, typeof(string));

    Hildon.TouchSelector book_selector;
    Hildon.TouchSelector nums_selector;

    public VerseSelector(Gtk.Window? parent)
    {
        title = "Select verse";
        set_transient_for(parent);

        add_button(Gtk.STOCK_OK, Gtk.ResponseType.OK);

        foreach (var book in Books.instance.books)
        {
            Gtk.TreeIter iter;
            book_store.append(out iter);
            book_store.set(iter, 0, book.name());
        }

        book_selector = new Hildon.TouchSelector();
        book_selector.append_text_column(book_store, true);

        nums_selector = new Hildon.TouchSelector();
        nums_selector.append_text_column(chapter_store, true);
        nums_selector.append_text_column(verse_store, true);

        book_selector.changed.connect(on_changed);
        nums_selector.changed.connect(on_changed);

        var hbox = new Gtk.HBox(false, 0);
        hbox.pack_start(book_selector, true, true, 0);
        hbox.pack_start(nums_selector, true, true, 0);

        hbox.set_size_request(1, 390);

        vbox.add(hbox);
        vbox.show_all();
    }


    public void update_language()
    {
        Gtk.TreeIter iter;
        book_store.get_iter_first(out iter);

        foreach (var book in Books.instance.books)
        {
            book_store.set(iter, 0, book.name());

            book_store.iter_next(ref iter);
        }
    }


    bool manual_call = false;
    void on_changed(int column)
    {
        if (manual_call) return;

        manual_call = true;

        int act0 = book_selector.get_active(0);
        int act1 = nums_selector.get_active(0);
        int act2 = nums_selector.get_active(1);

        if (act0 != -1)
        {
            var book = Books.instance.books.nth(act0).data;
            fill_with_numbers(chapter_store, book.chapter_count);
            nums_selector.set_active(0, act1);

            if (act1 != -1)
            {
                if (act1 > book.chapter_count - 1)
                    act1 = book.chapter_count - 1;

                fill_with_numbers(verse_store, book.verse_count[act1]);
                nums_selector.set_active(1, act2);
            }
        }

        manual_call = false;
    }


    void fill_with_numbers(Gtk.ListStore store, int count)
    {
        if (store.length < count)
        {
            Gtk.TreeIter iter;
            for (var i = store.length + 1; i <= count; i++)
            {
                store.append(out iter);
                store.set(iter, 0, i.to_string());
            }
        }
        else if (store.length > count)
        {
            Gtk.TreeIter iter;
            for (var i = store.length - count; i > 0; i--)
            {
                store.get_iter_first(out iter);
                store.remove(iter);
            }

            store.get_iter_first(out iter);
            for (var i = 0; i < store.length; i++)
            {
                store.set(iter, 0, (i+1).to_string());
                store.iter_next(ref iter);
            }
        }
    }



    public Location get_location()
    {
        int act0 = book_selector.get_active(0);
        int act1 = nums_selector.get_active(0);
        int act2 = nums_selector.get_active(1);

        Book book = null;
        if (act0 != -1)
            book = Books.instance.books.nth(act0).data;

        return Location(book, act1+1, act2+1);
    }

    public void set_location(Location location)
    {
        if (location.valid())
        {
            book_selector.set_active(0, Books.instance.books.index(location.book));
            nums_selector.set_active(0, location.chapter - 1);
            nums_selector.set_active(1, location.verse - 1);

            book_selector.center_on_selected();
            nums_selector.center_on_selected();
        }
    }
}
