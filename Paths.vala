namespace Paths
{
    public string user_dir()
    {
        var dirname = Environment.get_home_dir() + Path.DIR_SEPARATOR_S + ".nwtbible/";
        DirUtils.create(dirname, 0750);
        return dirname;
    }

    public string share_dir()
    {
#if DEBUG
        return "/home/user/NWTBible/";
#else
        return "/usr/share/nwtbible/";
#endif
    }

    public string share_url()
    {
       return "file://" + share_dir();
    }

    public string css()
    {
       return share_url() + "style.css";
    }

    public string js()
    {
       return share_url() + "script.js";
    }
    public string js_basename()
    {
       return "script.js";
    }


    public string langs_ini()
    {
        return share_dir() + "langs.ini";
    }

    public string books_ini()
    {
        return share_dir() + "books.ini";
    }


    public string welcome_url()
    {
        return share_url() + "welcome.html";
    }
}
