public class MainWindow: Hildon.StackableWindow
{
    private VerseSet verse_set = VerseSet.invalid();

    private VerseSelector verse_selector;

    private WebKit.WebView web_view;

    private He.FullscreenButton fb;

    private Gtk.Toolbar toolbar;

    private Hildon.PickerButton lang_button;

    private Gtk.ToggleAction select_text_action;

    private Hildon.PannableArea pannable;


    private Hildon.AppMenu app_menu;
    private Hildon.Button copy_selected;


    private double zoom;
    private uint F7 = Gdk.keyval_from_name("F7");
    private uint F8 = Gdk.keyval_from_name("F8");


    private Storage storage;
    private Fetcher fetcher;


    private Bookmarks bookmarks;
    private BookmarksWindow bookmarks_window;


    private FindWindow find_window;


    private NWTSettings settings = new NWTSettings();
    private bool going_to_set_scroll = false;


    public MainWindow()
    {
        // Hildon.gtk_window_set_portrait_flags(this, Hildon.PortraitFlags.SUPPORT|Hildon.PortraitFlags.REQUEST);

        var lang = settings.get_language();
        if (lang != null)
            Languages.instance.current = lang;


        storage = new Storage();
        fetcher = new Fetcher(storage);


        var select_verse_action = new Gtk.Action(
            "Select verse...", "Select verse...", "Select book, chapter and verse", null
        );
        select_verse_action.set("icon_name", "general_foldertree");
        select_verse_action.activate.connect(on_select_verse_action);

        var prev_chapter_action = new Gtk.Action(
            "Previous chapter", "Previous chapter", "Switch to previous chapter", null
        );
        prev_chapter_action.set("icon_name", "general_back");
        prev_chapter_action.activate.connect(on_prev_chapter_action);

        var next_chapter_action = new Gtk.Action(
            "Next chapter", "Next chapter", "Switch to next chapter", null
        );
        next_chapter_action.set("icon_name", "general_forward");
        next_chapter_action.activate.connect(on_next_chapter_action);

        var fullscreen_action = new Gtk.Action(
            "Fullscreen", "Fullscreen", "Fullscreen", null
        );
        fullscreen_action.set("icon_name", "general_fullsize");
        fullscreen_action.activate.connect(() => { fullscreen(); toolbar.hide(); });

        select_text_action = new Gtk.ToggleAction(
            "Select text", "Select text", "Select text", null
        );
        select_text_action.set("icon_name", "browser_panning_mode_off");
        select_text_action.toggled.connect(on_select_text_action_toggled);

        var add_bookmark_action = new Gtk.Action(
            "Add bookmark", "Add bookmark", "Bookmark selected verses", null
        );
        add_bookmark_action.set("icon_name", "general_bookmark");
        add_bookmark_action.activate.connect(on_add_bookmark_action);

        var bookmarks_action = new Gtk.Action(
            "Bookmark", "Bookmark", "Show bookmarks", null
        );
        bookmarks_action.set("icon_name", "general_mybookmarks_folder");
        bookmarks_action.activate.connect(on_bookmarks_action);

        var find_action = new Gtk.Action(
            "Search", "Search", "Full-text search", null
        );
        find_action.set("icon_name", "general_search");
        find_action.activate.connect(on_find_action);

#if DEBUG
        var dbg_action = new Gtk.Action("dbg", "dbg", "dbg", null);
        dbg_action.activate.connect(dbg);
#endif

        toolbar = new Gtk.Toolbar();
        toolbar.insert(select_verse_action.create_tool_item() as Gtk.ToolItem, -1);
        toolbar.insert(prev_chapter_action.create_tool_item() as Gtk.ToolItem, -1);
        toolbar.insert(next_chapter_action.create_tool_item() as Gtk.ToolItem, -1);
        toolbar.insert(new Gtk.SeparatorToolItem(), -1);
        toolbar.insert(select_text_action.create_tool_item() as Gtk.ToolItem, -1);
        toolbar.insert(new Gtk.SeparatorToolItem(), -1);
        toolbar.insert(add_bookmark_action.create_tool_item() as Gtk.ToolItem, -1);
        toolbar.insert(bookmarks_action.create_tool_item() as Gtk.ToolItem, -1);
        toolbar.insert(new Gtk.SeparatorToolItem(), -1);
        toolbar.insert(find_action.create_tool_item() as Gtk.ToolItem, -1);

        var filler = new Gtk.ToolItem();
        filler.set_expand(true);
        toolbar.insert(filler, -1);

#if DEBUG
        toolbar.insert(dbg_action.create_tool_item() as Gtk.ToolItem, -1);
#endif
        toolbar.insert(fullscreen_action.create_tool_item() as Gtk.ToolItem, -1);

        add_toolbar(toolbar);


        app_menu = new Hildon.AppMenu();

        lang_button = LangButton.create();
        lang_button.value_changed.connect(on_choose_language_action);
        app_menu.append(lang_button);

        var download_button = new Hildon.Button.with_text(
            Hildon.SizeType.AUTO,
            Hildon.ButtonArrangement.HORIZONTAL,
            "Download Bible",
            ""
        );
        download_button.clicked.connect(on_download_action);
        app_menu.append(download_button);

        var clear_cache_button = new Hildon.Button.with_text(
            Hildon.SizeType.AUTO,
            Hildon.ButtonArrangement.HORIZONTAL,
            "Clear cache",
            ""
        );
        clear_cache_button.clicked.connect(on_clear_cache_action);
        app_menu.append(clear_cache_button);

        copy_selected = new Hildon.Button.with_text(
            Hildon.SizeType.AUTO,
            Hildon.ButtonArrangement.HORIZONTAL,
            "Copy selected",
            ""
        );
        copy_selected.clicked.connect(() => {
            web_view.copy_clipboard();
        });
        app_menu.append(copy_selected);

        // Hiding Copy button if there is no selected text
        app_menu.map.connect(() => {
            if (web_view.can_copy_clipboard()) copy_selected.show();
            else copy_selected.hide();
        });

        var welcome_button = new Hildon.Button.with_text(
            Hildon.SizeType.AUTO,
            Hildon.ButtonArrangement.HORIZONTAL,
            "About NWTBible",
            ""
        );
        welcome_button.clicked.connect(show_welcome);
        app_menu.append(welcome_button);

        app_menu.show_all();
        set_app_menu(app_menu);


        verse_selector = new VerseSelector(this);


        web_view = new WebKit.WebView();

        web_view.copy_clipboard.connect(() => {
            Hildon.Banner.show_information(this, null, "Copied to clipboard");
        });
        web_view.motion_notify_event.connect(catch_motion_event);
        web_view.script_alert.connect(on_script_alert);
        web_view.load_finished.connect(on_load_finished);

        pannable = new Hildon.PannableArea();
        pannable.add(web_view);
        add(pannable);

        pannable.motion_notify_event.connect(on_pannable_mouse_move);
        pannable.button_press_event.connect(on_pannable_mouse_press);

        fb = new He.FullscreenButton(this);
        fb.clicked.connect(() => { unfullscreen(); toolbar.show(); });


        Hildon.gtk_window_enable_zoom_keys(this, true);
        key_press_event.connect(on_key_press);


        realize.connect(() => {
            // Enabling compositing to make HeFullscreenButton work properly
            Gdk.property_change(
                window,
                Gdk.Atom.intern("_HILDON_NON_COMPOSITED_WINDOW", true),
                Gdk.Atom.intern("INTEGER", true), 32,
                Gdk.PropMode.REPLACE,
                {0}, 1);
        });


        bookmarks = new Bookmarks(Paths.user_dir() + "bookmarks.ini");
        bookmarks_window = new BookmarksWindow();
        bookmarks_window.sort_type = settings.get_bookmarks_sort_type();
        bookmarks_window.delete_event.connect(bookmarks_window.hide_on_delete);
        bookmarks_window.bookmark_selected.connect(on_bookmark_selected);

        find_window = new FindWindow(storage);
        find_window.delete_event.connect(find_window.hide_on_delete);
        find_window.found_location_activated.connect(on_found_location_activated);


        more_config();

        zoom = settings.get_zoom();
        verse_set.chapter = settings.get_chapter();
        if (verse_set.valid())
        {
            show_verse_set(verse_set);
            going_to_set_scroll = true;
        }
        else
            show_welcome();


        Idle.add(() => {
            if (settings.get_swipe_notice_shown() == false)
            {
                var note = new Hildon.Note.information(this,
                    "With this update of NWTBible you can use swipe guesture from edge " +
                    "to the center of the screen to go to next or previous chapter. This " +
                    "also works in fullscreen mode.\n" +
                    "\n" +
                    "Thank you for using NWTBible!"
                );
                note.run();
                note.destroy();

                settings.set_swipe_notice_shown(true);
            }
            return false;
        });
    }

    ~MainWindow()
    {
        settings.set_chapter(verse_set.chapter);
        settings.set_language(Languages.instance.current);

        // Calling JavaScript seems to be unavailable in destructor

        settings.set_bookmarks_sort_type(bookmarks_window.sort_type);

        bookmarks_window.destroy();
        find_window.destroy();

        copy_selected = null; // To ensure that button is destroyed before app_menu
        lang_button = null;
        app_menu = null;
    }


#if DEBUG
    void dbg()
    {
        web_view.execute_script("pan_to_right()");
    }
#endif


    void more_config()
    {   // setting this in constructor makes valac feel bad
        web_view.settings.user_stylesheet_uri = Paths.css();

        destroy.connect(() => {
            var scroll = NWTBible.exec_js_int(web_view, "get_scroll()");
            settings.set_scroll(scroll);
        });
    }


    bool on_script_alert(WebKit.WebFrame frame, string msg)
    {
        stdout.printf("ALERT: %s\n", msg);
        return true;
    }


    void on_prev_chapter_action()
    {
        var new_chapter = verse_set.chapter.prev();

        if (new_chapter != null)
        {
            verse_set.chapter = new_chapter;
            verse_set.clear_verses();
            show_verse_set(verse_set);
        }
    }


    void on_next_chapter_action()
    {
        var new_chapter = verse_set.chapter.next();

        if (new_chapter != null)
        {
            verse_set.chapter = new_chapter;
            verse_set.clear_verses();
            show_verse_set(verse_set);
        }
    }


    void on_select_verse_action()
    {
        update_highlighted_verse_set();

        verse_selector.set_location(Location(verse_set.chapter.book, verse_set.chapter.chapter,
            verse_set.verses.length == 0 ? 1 : verse_set.verses[0]
        ));

        var res = verse_selector.run();
        verse_selector.hide();
        if (res == Gtk.ResponseType.OK)
        {
            var location = verse_selector.get_location();
            verse_set = VerseSet.from_location(location);
            show_verse_set(verse_set);
        }
    }


    void show_verse_set(VerseSet verse_set)
    {
        title = verse_set.chapter.to_string();

        Hildon.gtk_window_set_progress_indicator(this, 1);
        var html = fetcher.fetch_chapter(verse_set.chapter);
        Hildon.gtk_window_set_progress_indicator(this, 0);

        if (html != null)
            web_view.load_html_string(html, Paths.share_url());
        else
            web_view.load_html_string("<h1>Loading failed</h1><h2>Please check your network connection</h2>", Paths.share_url());
    }


    void on_load_finished()
    {
        web_view.execute_script("on_chapter_loaded(%s, %s)".printf(
            verse_set.js_list(),
            "%f".printf(zoom).replace(",", ".")
        ));

        if (going_to_set_scroll)
        {
            web_view.execute_script("set_scroll(%d)".printf(settings.get_scroll()));
            going_to_set_scroll = false;
        }
    }



    void on_choose_language_action()
    {
        Idle.add(() => {
            var idx = lang_button.get_selector().get_active(0);
            if (idx != -1)
            {
                Languages.instance.current = Languages.instance.langs().nth(idx).data;

                verse_selector.update_language();

                update_highlighted_verse_set();
                if (verse_set.valid())
                    show_verse_set(verse_set);
            }

            return false;
        });
    }


    void on_download_action()
    {
        var confirmation = new Hildon.Note.confirmation(this,
            "Are you ready to download whole Bible in current language?\n" +
            "This may take some time and you probably should not do it via GSM network. " +
            "You can cancel downloading at any time and continue it later."
        );

        var res = confirmation.run();
        confirmation.destroy();

        if (res == Gtk.ResponseType.OK)
        {
            var progress = new Gtk.ProgressBar();

            var dialog = new Hildon.Note.cancel_with_progress_bar(this, "Starting...", progress);
            dialog.show();

            var stopped = false;
            dialog.response.connect(() => {
                dialog.hide();
                stopped = true;
            });


            var total_chapters = 0;
            foreach (var book in Books.instance.books)
                total_chapters += book.chapter_count;

            var chapters_done = 0, errors = 0;
            int chapters_in_book_done;

            bool was_actual_download = false;

            var f = fetcher;
            foreach (var book in Books.instance.books)
            {
                chapters_in_book_done = 0;

                var chapters_in_book = book.chapter_count;
                var chapter = Chapter(book, 1);

                f.fetch_book(book, (ok, cached) => {
                    // This lambda must not use book variable from outer scope because this triggers bug in valac

                    if (! cached)
                        was_actual_download = true;

                    chapters_done++;
                    chapters_in_book_done++;
                    if (! ok) errors++;

                    chapter.chapter = chapters_in_book_done;
                    dialog.description = chapter.to_string() + @"/$chapters_in_book";

                    if (errors > 0)
                        dialog.description += @" ($errors errors)";

                    progress.set_fraction((float)chapters_done / total_chapters);

                    return ! stopped;
                });

                if (stopped)
                    break;
            }

            dialog.hide();
            dialog.destroy();

            if (errors > 0)
            {
                var note = new Hildon.Note.information(this, "%d chapters were not fetched due to network errors. You may restart downloading to retry.".printf(errors));
                note.run();
                note.destroy();
            }
            else
                if (! was_actual_download)
                {
                    var note = new Hildon.Note.information(this, "You have already downloaded whole Bible in selected language");
                    note.run();
                    note.destroy();
                }
        }
    }


    void on_clear_cache_action()
    {
        var confirmation = new Hildon.Note.confirmation(this,
            "Are you sure you want to wipe all downloaded chapters?"
        );

        var res = confirmation.run();
        confirmation.destroy();

        if (res == Gtk.ResponseType.OK)
            fetcher.clear_cache();
    }


    private bool on_key_press(Gdk.EventKey event)
    {
        if (event.keyval == F7)
        {
            set_zoom(zoom * 1.2);
            return true;
        }

        if (event.keyval == F8)
        {
            set_zoom(zoom / 1.2);
            return true;
        }

        return false;
    }

    const double max_zoom = 1.2 * 1.2 * 1.2 * 1.2;
    void set_zoom(double zoom)
    {
        // 1.2⁶ ≈ 3.0
        zoom = double.min(zoom, max_zoom);
        zoom = double.max(zoom, 1.0 / max_zoom);

        this.zoom = zoom;

        settings.set_zoom(zoom);

        update_zoom();
    }

    void update_zoom()
    {
        web_view.execute_script("set_zoom('%f')".printf(zoom).replace(",", "."));
    }


    void on_select_text_action_toggled()
    {
        if (select_text_action.active)
        {
            web_view.motion_notify_event.disconnect(catch_motion_event);
            web_view.motion_notify_event.connect(pass_motion_event);
            pannable.enabled = false;
        }
        else
        {
            web_view.motion_notify_event.disconnect(pass_motion_event);
            web_view.motion_notify_event.connect(catch_motion_event);
            pannable.enabled = true;
        }

        if (select_text_action.active)
            select_text_action.set("icon_name", "browser_panning_mode_on");
        else
            select_text_action.set("icon_name", "browser_panning_mode_off");

        web_view.execute_script("enable_selecting(%s)".printf(select_text_action.active ? "false" : "true"));
    }


    bool catch_motion_event() { return true; }
    bool pass_motion_event() { return false; }



    void on_add_bookmark_action()
    {
        update_highlighted_verse_set();

        {
            var dlg = new Gtk.Dialog.with_buttons(
                "Add bookmark: %s".printf(verse_set.to_string()),
                this,
                Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                Gtk.STOCK_OK,
                Gtk.ResponseType.ACCEPT,
                Gtk.STOCK_CANCEL,
                Gtk.ResponseType.REJECT
            );
            dlg.set_default_response(Gtk.ResponseType.ACCEPT);

            var entry = new Hildon.Entry(Hildon.SizeType.AUTO);
            entry.set_placeholder("Description");
            entry.set_activates_default(true);

            var caption = new Hildon.Caption((Gtk.SizeGroup)null, "Description", entry, (Gtk.Widget)null, Hildon.CaptionStatus.OPTIONAL);

            dlg.vbox.add(caption);

            dlg.show_all();
            var response = dlg.run();
            dlg.destroy();

            if (response == Gtk.ResponseType.ACCEPT)
            {
                bookmarks.append(new Bookmark(verse_set, entry.get_text()));
                Hildon.Banner.show_information(this, null, "Bookmark added: %s".printf(verse_set.to_string()));
            }
        }
    }



    void on_bookmarks_action()
    {
        bookmarks_window.fill(bookmarks);
        bookmarks_window.show();
    }


    void on_bookmark_selected(Bookmark bookmark)
    {
        bookmarks_window.hide();

        verse_set = bookmark.verse_set;
        show_verse_set(verse_set);
    }



    void update_highlighted_verse_set()
    {
        verse_set.set_verses(NWTBible.exec_js_int_arr(web_view, "get_highlighted()"));
    }


    void on_find_action()
    {
        find_window.show();

        if (settings.get_find_notice_shown() == false)
        {
            var note = new Hildon.Note.information(find_window,
                "Search function only works on chapters which was already downloaded. " +
                "If you want to search in whole Bible you need to download it in current " +
                "language using the button in the main menu.");
            note.run();
            note.destroy();
            settings.set_find_notice_shown(true);
        }
    }



    void on_found_location_activated(Chapter chapter)
    {
        verse_set.chapter = chapter;
        verse_set.clear_verses();

        title = chapter.to_string();

        var html = fetcher.fetch_chapter(chapter);

        if (html != null)
        {
            html = NWTBible.mark_matches(
                html,
                find_window.get_search_text(),
                "<span class='found' name='found'>",
                "</span>"
            );

            web_view.load_html_string(html, Paths.share_url());
        }
        else
            web_view.load_html_string("<h1>Loading failed</h1><h2>Please check your network connection</h2>", Paths.share_url());


        find_window.hide();
    }



    void show_welcome()
    {
        title = "NWTBible";
        web_view.load_uri(Paths.welcome_url());
    }




    int pannable_press_x;
    int pannable_press_y;
    bool pannable_pressed = false;

    bool on_pannable_mouse_press(Gdk.EventButton event)
    {
        pannable_pressed = true;
        pannable_press_x = (int)event.x;
        pannable_press_y = (int)event.y;

        return false;
    }


    bool already_in_progress = false;
    const int swipe_border = 100;
    const int swipe_length = 300;
    bool on_pannable_mouse_move(Gdk.EventMotion event)
    {
        if (already_in_progress) return false;

        already_in_progress = true;

        int x = (int)event.x;
        int y = (int)event.y;

        if (pannable_pressed)
        {
            if ((pannable_press_y - y).abs() < 100)
            {
                if (pannable_press_x < swipe_border && x > swipe_length)
                {
                    on_prev_chapter_action();
                    pannable_pressed = false;
                }
                else if (pannable_press_x > pannable.allocation.width - swipe_border && x < pannable.allocation.width - swipe_length)
                {
                    on_next_chapter_action();
                    pannable_pressed = false;
                }
            }
        }

        already_in_progress = false;
        return false;
    }
}
