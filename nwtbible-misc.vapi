namespace He
{
    [CCode(cheader_filename = "he-fullscreen-button.h")]
    public class FullscreenButton: GLib.Object
    {
        public FullscreenButton(Gtk.Window parent_window);

        public void enable();
        public void disable();

        public unowned Gtk.Widget get_overlay();
        public unowned Gtk.Window get_window();

        public signal void clicked();
    }
}

namespace Hildon
{
    [CCode(cheader_filename = "hildon/hildon-gtk.h")]
    public void gtk_window_enable_zoom_keys(Gtk.Window window, bool enable);
}

[CCode(cprefix = "", lower_case_cprefix = "", cheader_filename = "X11/Xlib.h,X11/Xatom.h")]
namespace X
{
    public const X.Atom XA_INTEGER;
}
