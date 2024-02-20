using Gtk4, GtkObservables

function main()
    win = GtkWindow()
    show(win)
    @async Gtk4.GLib.glib_main()
    Gtk4.GLib.waitforsignal(win, :close_request)
    @info "closed the window"
end
