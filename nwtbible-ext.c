#include <stdio.h>


//// WebKit JS stuff

#include <webkit/webkit.h>
#include <JavaScriptCore/JSValueRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <JavaScriptCore/JSContextRef.h>

#include <string.h>


JSContextRef nwtbible_js_context(WebKitWebView *web_view)
{
    return webkit_web_frame_get_global_context(webkit_web_view_get_main_frame(web_view));
}


JSValueRef nwtbible_exec_js(WebKitWebView *web_view, const char *script)
{
    g_return_val_if_fail(WEBKIT_IS_WEB_VIEW(web_view), NULL);
    g_return_val_if_fail(script, NULL);



    JSStringRef str = JSStringCreateWithUTF8CString(script);

    JSValueRef value = JSEvaluateScript(
        nwtbible_js_context(web_view),
        str,
        0,
        0,
        0,
        0
    );

    JSStringRelease(str);

    return value;
}


gint nwtbible_exec_js_int(WebKitWebView *web_view, const gchar *script)
{
    JSValueRef value = nwtbible_exec_js(web_view, script);
    if (value == 0)
        return 0;

    return (int) JSValueToNumber(
        nwtbible_js_context(web_view),
        value,
        NULL
    );
}

gint* nwtbible_exec_js_int_arr(WebKitWebView *web_view, const gchar *script, gint *length)
{
    *length = 0;

    JSValueRef value = nwtbible_exec_js(web_view, script);
    if (value == 0)
        return 0;

    JSContextRef ctx = nwtbible_js_context(web_view);
    JSObjectRef obj = JSValueToObject(ctx, value, 0);

    if (obj == NULL)
        return 0;

    JSPropertyNameArrayRef name_array = JSObjectCopyPropertyNames(ctx, obj);
    *length = JSPropertyNameArrayGetCount(name_array);
    JSPropertyNameArrayRelease(name_array);

    gint *arr = g_new(gint, *length);
    int i;
    for (i = 0; i < *length; i++)
        arr[i] = (int)JSValueToNumber(
            ctx,
            JSObjectGetPropertyAtIndex(ctx, obj, i, NULL),
            NULL
        );

    return arr;
}


//// SQLite & Unicode stuff
// FIXME: works only for one DB

#include <sqlite3.h>
#include <unicode/ucol.h>
#include <unicode/ucnv.h>
#include <unicode/usearch.h>


void nwtbible_unicode_like(sqlite3_context *ctx, int n, sqlite3_value **args)
{
    UErrorCode err = 0;

    UCollator *collator = (UCollator*)sqlite3_user_data(ctx);

    UStringSearch *search = usearch_openFromCollator(
        (UChar*)sqlite3_value_text16(args[0]),
        -1,
        (UChar*)sqlite3_value_text16(args[1]),
        -1,
        collator,
        0,
        &err
    );

    int result = 0;

    int pos = usearch_first(search, &err);
    if (pos != -1)
        result = 1;

    usearch_close(search);

    sqlite3_result_int(ctx, result);
}

UCollator *collator = 0;

void nwtbible_install_unicode_like(sqlite3 *db)
{
    if (collator != 0)
        ucol_close(collator);

    UErrorCode err = 0;
    collator = ucol_open("", &err);
    ucol_setStrength(collator, UCOL_PRIMARY);

    sqlite3_create_function(
        db,
        "like",
        2,
        SQLITE_ANY,
        collator,
        nwtbible_unicode_like,
        0,
        0
    );
}

void nwtbible_uninstall_unicode_like(sqlite3 *db)
{
    if (collator != 0)
        ucol_close(collator);
}



char* nwtbible_mark_matches(const char *haystack, const char *needle, const char *before, const char *after)
{
    UErrorCode err = 0;

    long haystack_len, before_len, after_len;

    UChar* u_haystack = g_utf8_to_utf16(haystack, -1, NULL, &haystack_len, NULL);
    UChar* u_needle   = g_utf8_to_utf16(needle, -1, NULL, NULL, NULL);
    UChar* u_before   = g_utf8_to_utf16(before, -1, NULL, &before_len, NULL);
    UChar* u_after    = g_utf8_to_utf16(after, -1, NULL, &after_len, NULL);


    UCollator *collator = ucol_open("", &err);
    ucol_setStrength(collator, UCOL_PRIMARY);

    UStringSearch *search = usearch_openFromCollator(u_needle, -1, u_haystack, -1, collator, NULL, &err);

    int pos;
    int matches = 0;

    pos = usearch_first(search, &err);
    do
    {
        if (pos != USEARCH_DONE)
            matches++;

        pos = usearch_next(search, &err);
    } while (pos != USEARCH_DONE);
    usearch_reset(search);


    int result_len = haystack_len + matches * (before_len + after_len);
    UChar *u_result = g_new(UChar, result_len + 1);
    u_result[result_len] = 0x0000;


    UChar *out_p = u_result;
    UChar *in_p = u_haystack;

    pos = usearch_first(search, &err);
    do
    {
        if (pos != USEARCH_DONE)
        {
            UChar *match_p = &u_haystack[pos];

            memcpy(out_p, in_p, sizeof(UChar) * (match_p - in_p));
            out_p += match_p - in_p;
            in_p = match_p;

            memcpy(out_p, u_before, sizeof(UChar) * before_len);
            out_p += before_len;

            int match_len = usearch_getMatchedLength(search);
            memcpy(out_p, in_p, sizeof(UChar) * (match_len));
            out_p += match_len;
            in_p += match_len;

            memcpy(out_p, u_after, sizeof(UChar) * after_len);
            out_p += after_len;
        }

        pos = usearch_next(search, &err);
    } while (pos != USEARCH_DONE);

    memcpy(out_p, in_p, sizeof(UChar) * (haystack_len - (in_p - u_haystack)));



    usearch_close(search);
    ucol_close(collator);

    char *result = g_utf16_to_utf8(u_result, -1, NULL, NULL, NULL);

    g_free(u_haystack);
    g_free(u_needle);
    g_free(u_after);
    g_free(u_before);
    g_free(u_result);

    return result;
}
