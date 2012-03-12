[CCode(cheader_filename="nwtbible-ext.h", cprefix="NWTBible", lower_case_cprefix="nwtbible_")]
namespace NWTBible
{
    public int exec_js_int(WebKit.WebView web_view, string script);
    public int[] exec_js_int_arr(WebKit.WebView web_view, string script);


    public void install_unicode_like(Sqlite.Database db);
    public void uninstall_unicode_like(Sqlite.Database db);


    public string mark_matches(string haystack, string needle, string before, string after);
}
