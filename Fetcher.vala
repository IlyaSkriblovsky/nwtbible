public class Fetcher
{
//    private static Fetcher _instance = null;
//    public static Fetcher instance
//    {
//        get
//        {
//            if (_instance == null)
//                _instance = new Fetcher();
//            return _instance;
//        }
//    }
//
//
    private Storage storage;


    public Fetcher(Storage storage)
    {
        this.storage = storage;
    }



    public void clear_cache()
    {
        storage.clear_cache();
    }


    public string? fetch_chapter(Chapter chapter)
    {
        if (! chapter.valid())
            return "<p><span class='error'>Invalid chapter</span></p>";

        var cached = storage.load_cached_chapter(chapter);
        if (cached != null)
            return cached;

        var url = chapter_url(chapter);

        var session = new Soup.SessionAsync();
        var message = new Soup.Message("GET", url);

        var res = session.send_message(message);
        if (res == 200)
        {
            var content = transform_content((string)message.response_body.data, url, chapter);
            storage.cache_chapter(chapter, content);
            return content;
        }
        else
            return null;
    }


    // Callback will receive boolean argument equal to true if loading of
    // chapter was successful or false in case of error
    // Callback must return true if downloading should continue or false
    // if fetch_book() must stop downloading
    public delegate bool ChapterLoadedCallback(bool ok, bool cached);

    // This method will download whole book. Callback will be called after
    // downloading of each chapter. fetch_book will run its own mainloop, so
    // application's UI will be active.
    public void fetch_book(Book book, ChapterLoadedCallback callback)
    {
        var session = new Soup.SessionAsync();

        var loop = new MainLoop();

        var done = 0;

        for (var chapter = 1; chapter <= book.chapter_count; chapter++)
        {
            if (storage.has_cached_chapter(Chapter(book, chapter)))
            {
                done++;
                if (callback(true, true) == false)
                {
                    session.abort();
                    loop.quit();
                }
            }
            else
            {
                var message = new Soup.Message("GET", chapter_url(Chapter(book, chapter)));

                session.queue_message(message, (session, msg) => {
                    bool ok;
                    if (msg.status_code == 200)
                    {
                        var url = msg.get_uri().to_string(false);
                        var msg_chapter = url[-7:-4].to_int();

                        var chp = Chapter(book, msg_chapter);
                        var content = transform_content((string)msg.response_body.data, url, chp);
                        storage.cache_chapter(chp, content);

                        ok = true;
                    }
                    else
                        ok = false;

                    if (callback(ok, false) == false)
                    {
                        session.abort();
                        loop.quit();
                    }

                    done++;
                    if (done == book.chapter_count)
                        loop.quit();
                });

                message.unref();
            }
        }

        if (done < book.chapter_count)
            loop.run();
    }

    public string chapter_url(Chapter chapter, Language? lang = null)
    {
        if (! chapter.valid())
            return "";

        if (lang == null)
            lang = Languages.instance.current;

        return "http://watchtower.org"
            + Languages.instance.current.bible_url
            + chapter.book.code
            + "/chapter_%03d.htm".printf(chapter.chapter);
    }


    string transform_content(string content, string base_url, Chapter chapter)
    {
        char[] utf8 = content.to_utf8();

        Xml.Doc input = Html.Doc.read_memory(utf8, utf8.length, base_url);


        // We need XHTML DTD because John 8 contains empty <a/> which is
        // treated incorrectly in HTML mode
        var output = new Html.Doc(
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd",
            "-//W3C//DTD XHTML 1.0 Transitional//EN"
        );

        unowned Xml.Node* html = new Xml.Node(null, "html");
        html->set_lang(input.get_root_element()->get_prop("xml:lang"));

        unowned Xml.Node* head = html->new_child(null, "head");
        unowned Xml.Node* script = head->new_child(null, "script");
        script->set_prop("src", Paths.js_basename());

        unowned Xml.Node* body = html->new_child(null, "body");

        unowned Xml.Node* chapter_div = body->new_child(null, "div");
        chapter_div->set_prop("class", "chapter");

        chapter_div->new_child(null, "h3")->add_content(chapter.to_string());

        body->add_child(chapter_div);

        find_verses(input.get_root_element(), chapter_div);

        output.set_root_element(html);

        string dump;
        output.dump_memory_enc_format(out dump);

        return dump;
    }


    unowned Xml.Node* find_child(Xml.Node *root, string name)
    {
        var child = root->children;
        while (child != null)
        {
            if (child->name == name)
                return child;
            child = child->next;
        }

        return null;
    }

    void find_verses(Xml.Node *root, Xml.Node *out_div)
    {
        var body = find_child(root, "body");
        if (body == null)
        {
            stderr.printf("body == null\n");
            return;
        }

        var div = find_child(body, "div");
        if (div == null)
        {
            stderr.printf("div == null\n");
            return;
        }

        var h3found = false;
        var child = div->children;
        while (child != null)
        {
            //if (child->name == "p" && child->has_prop("class") == null)

            if (child->name == "h3")
                h3found = true;

            if (h3found && child->name == "p")
            {
                out_div->add_child(child->copy(1));
            }

            child = child->next;
        }
    }
}
