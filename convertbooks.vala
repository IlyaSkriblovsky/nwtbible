public void main(string[] args)
{
    try
    {
        var key_file = new KeyFile();
        key_file.load_from_file("books-by-lang.ini", KeyFileFlags.NONE);

        var out_file = new KeyFile();

        foreach (var lang in key_file.get_groups())
            foreach (var chap in key_file.get_keys(lang))
            {
                out_file.set_string(chap, lang, key_file.get_string(lang, chap));
            }

        FileStream.open("books.ini", "w").printf("%s", out_file.to_data());
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
