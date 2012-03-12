public static void main(string[] args)
{
    Gtk.init(ref args);
    Hildon.init();

    var program = Hildon.Program.get_instance();

    var window = new MainWindow();

    program.add_window(window);
    window.destroy.connect(Gtk.main_quit);
    window.show_all();

    Gtk.main();
}
