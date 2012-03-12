public class Language
{
    public string engname { get; private set; }
    public string selfname { get; private set; }
    public string code { get; private set; }
    public string bible_url { get; private set; }

    public Language(string engname, string selfname, string code, string bible_url)
    {
        this.engname = engname;
        this.selfname = selfname;
        this.code = code;
        this.bible_url = bible_url;
    }
}


public class Languages
{
    private static Languages _instance = null;

    public static Languages instance
    {
        get
        {
            if (_instance == null)
                _instance = new Languages();

            return _instance;
        }
    }

    private Language _current = null;
    public Language current { get { return _current; } set { _current = value; } }

    private List<Language> _langs;
    private HashTable<string,unowned Language> _langByCode = new HashTable<string,unowned Language>((HashFunc)string.hash, str_equal);

    public Languages()
    {
        try
        {
            var key_file = new KeyFile();
            key_file.load_from_file(Paths.langs_ini(), KeyFileFlags.NONE);


            foreach (var code in key_file.get_groups())
            {
                var lang = new Language(
                    key_file.get_string(code, "engname"),
                    key_file.get_string(code, "selfname"),
                    code,
                    key_file.get_string(code, "bibleurl")
                );

                _langs.append(lang);
                _langByCode.insert(code, lang);

                if (code == "e")
                    current = lang;
            }
        }
        catch (FileError e)
        {
            stderr.printf("File error: %s\n", e.message);
        }
        catch (KeyFileError e)
        {
            stderr.printf("Key file error: %s\n", e.message);
        }
    }


    public unowned Language langByCode(string code)
    {
        return _langByCode.lookup(code);
    }

    public unowned List<Language> langs()
    {
        return _langs;
    }
}
