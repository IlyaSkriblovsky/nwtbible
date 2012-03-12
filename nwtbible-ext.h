#include <webkit/webkit.h>

gint nwtbible_exec_js_int(WebKitWebView *web_view, const gchar *script);
gint* nwtbible_exec_js_int_arr(WebKitWebView *web_view, const gchar *script, gint *length);

#include <sqlite3.h>

void nwtbible_install_unicode_like(sqlite3 *db);
void nwtbible_uninstall_unicode_like(sqlite3 *db);


char* nwtbible_mark_matches(const char *haystack, const char *needle, const char *before, const char *after);
