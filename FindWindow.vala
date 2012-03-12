public class FindWindow: Hildon.StackableWindow
{
    Gtk.ListStore store;

    Storage storage;

    Hildon.Entry entry;
    Hildon.Button button;


    public signal void found_location_activated(Chapter chapter);


    public FindWindow(Storage storage)
    {
        title = "Search";

        this.storage = storage;
        storage.found_new_chapter.connect(on_found_new_chapter);
        storage.search_finished.connect(on_search_finished);

        entry = new Hildon.Entry(
            Hildon.SizeType.FULLSCREEN_WIDTH | Hildon.SizeType.FINGER_HEIGHT
        );
        entry.activate.connect(on_button_clicked);

        var caption = new Hildon.Caption(
            (Gtk.SizeGroup)null,
            "Search text",
            entry,
            (Gtk.Widget)null,
            Hildon.CaptionStatus.OPTIONAL
        );

        button = new Hildon.Button.with_text(
            Hildon.SizeType.AUTO_WIDTH | Hildon.SizeType.FINGER_HEIGHT,
            Hildon.ButtonArrangement.VERTICAL,
            "      Search      ", ""
        );
        button.set_value_alignment(0.5f, 0.8f);
        button.clicked.connect(on_button_clicked);

        var hbox = new Gtk.HBox(false, 0);
        hbox.pack_start(caption, true, true, 0);
        hbox.pack_start(button, false, false, 0);

        store = new Gtk.ListStore(2, typeof(string), typeof(Chapter));

        var view = new Gtk.TreeView.with_model(store);
        view.insert_column_with_attributes(
            -1, "Location",
            new Gtk.CellRendererText(),
            "text", 0
        );
        view.row_activated.connect(on_row_activated);

        var pannable = new Hildon.PannableArea();
        pannable.add(view);

        var vbox = new Gtk.VBox(false, 0);

        vbox.pack_start(hbox, false, false, 0);
        vbox.pack_start(pannable, true, true, 0);

        add(vbox);
        vbox.show_all();
    }

    public string get_search_text()
    {
        return entry.get_text();
    }


    void on_button_clicked()
    {
        store.clear();
        storage.search_in_thread(entry.get_text());

        entry.sensitive = false;
        button.sensitive = false;
        button.value = "";
        Hildon.gtk_window_set_progress_indicator(this, 1);
    }


    void on_found_new_chapter(Chapter chapter)
    {
        Gtk.TreeIter iter;
        store.append(out iter);
        store.set(iter, 0, chapter.to_string());
        store.set(iter, 1, ref chapter);
    }

    void on_search_finished()
    {
        Hildon.gtk_window_set_progress_indicator(this, 0);
        entry.sensitive = true;
        button.sensitive = true;

        button.value = "%d chapters found".printf(store.iter_n_children(null));
    }


    void on_row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column)
    {
        Gtk.TreeIter iter;
        store.get_iter(out iter, path);

        Chapter *chapter;
        store.@get(iter, 1, out chapter);

        found_location_activated(*chapter);
    }
}
