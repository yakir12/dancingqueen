module DancingQueenClient

using Gtk4, GtkObservables
using ImageCore, ImageDraw
using Dates, HTTP, JSON3, TOML, JSONSchema
using Base.Threads

export main

const Color = RGB{N0f8}

const path2preferences = joinpath(@__DIR__, "..", "..", "..", "setup.toml")
const prefs = TOML.parsefile(path2preferences)
const nleds = prefs["arena"]["nleds"]
const camera_distance = prefs["detection"]["camera_distance"]
const path2data = joinpath(homedir(), "data")
const h = 400
const fps = 20
const ip = "http://192.168.50.187:8000" # through ethernet
const basic_settings = Dict("label" => "Off", "camera" => 2464, "suns" => [Dict("link_factor" => 0)])
const schema = Schema(read(joinpath(@__DIR__(), "schema.json"), String))

mkpath(path2data)

include("logbook.jl")
include(joinpath(@__DIR__, "..", "..", "..", "server/DancingQueen/src/helpers.jl"))

label_setups(setups) = [string(k, ": ", setup["label"]) => setup for (k, setup) in zip('a':'z', setups)]

bytes2img(b::Vector{UInt8}) = Color.(colorview(Gray, normedview(reshape(b, h, h))))

topoint(p) = ImageDraw.Point(reverse(Tuple(round.(Int, p))))

draw_beetle!(img, ::Nothing, _) = nothing
draw_beetle!(img, beetle, ratio) = draw!(img[], CirclePointRadius(topoint(ratio * beetle.c), 9), Color(1, 0, 1))

function set_frame!(img)
    HTTP.open("GET", "$ip/frame") do io
        while !eof(io)
            img.val = bytes2img(read(io))
        end
    end
end

function set_image!(img, state, camera)
    set_frame!(img)
    draw_beetle!(img, state[].beetle, h/camera)
    draw!(img[], ImageDraw.Cross(ImageDraw.Point(h ÷ 2, h ÷ 2), h ÷ 2 - 5), Color(1,1,1))
    notify(img)
end

function get_state()
    r = HTTP.request("GET", "$ip/state")
    return JSON3.read(String(r.body))
end

function file2setups(file)
    if !isfile(file)
        @error "settings file does not exist"
    end
    txt = read(file, String)
    if isempty(txt)
        @error "settings file was empty"
    end
    dict = TOML.tryparse(txt)
    if dict isa Base.TOML.ParserError
        @error "settings file had bad TOML format"
    end
    error_msg = validate(schema, dict)
    if !isnothing(error_msg)
        @error string(error_msg.x, " is wrong")
    end
    pushfirst!(dict["setups"], basic_settings)
end

function connect_canvas!(c, state, setup, running)
    img = Observable(bytes2img(rand(UInt8, h^2)))

    redraw = Gtk4.draw(c, img) do cnvs, img
        copy!(cnvs, img)
    end

    # maybe add camera 1080 to all the setups on loading
    frame_task = @spawn :default while running[]
        ta = @spawn :default set_image!(img, state, get(setup[], "camera", 1080))
        sleep(1/fps)
        fetch(ta)
    end
end

function get_kb_dropdown(setups, win)
    labels = label_setups(setups)
    dd = dropdown(labels)
    eck = GtkEventControllerKey(win)
    letters = first.(first.(labels))
    signal_connect(eck, "key-pressed") do controller, keyval, keycode, state
        i = findfirst(==(Char(keyval)), letters)
        if !isnothing(i)
            dd[] = first(labels[i])
        end
    end
    return dd, dd.mappedsignal
end

function main()
    file = joinpath(homedir(), "settings.toml")
    setups = file2setups(file)

    running = Ref(true)

    win = GtkWindow("DancingQueen")
    win[] = bx = GtkBox(:v)
    c = canvas(h, h)
    widget(c).hexpand = widget(c).vexpand = true
    f = GtkAspectFrame(h, h, 1, false)
    f[] = widget(c)
    push!(bx, f)
    dd, setup = get_kb_dropdown(setups, win)
    push!(bx, dd)

    state = Ref(get_state())
    logbook = Ref(LogBook(setup[], state[]))

    connect_canvas!(c, state, setup, running)

    state_task = @spawn :default while running[]
        state[] = get_state()
        log_print(logbook[], state[])
        yield()
    end

    h2 = on(setup) do setup
        HTTP.post("$ip/setup"; body=JSON3.write(setup))
        logbook[] = LogBook(setup, state[])
    end

    dd[] = dd[]


    show(win)
    @async Gtk4.GLib.glib_main()
    Gtk4.GLib.waitforsignal(win, :close_request)

    HTTP.post("$ip/setup"; body=JSON3.write(Dict("camera" => 0, "suns" => [Dict("link_factor" => 0)])))
    running[] = false

    return nothing
end

end # module DancingQueenClient
