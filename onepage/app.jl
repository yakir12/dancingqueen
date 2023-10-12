include("DancingQueen.jl")

using .DancingQueen

using TOML
using ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors, JSONSchema, JSONSchema
import Colors.N0f8

include("display.jl")
include("settings.jl")

using GenieFramework
@genietools

const client_fps = 10

isdir("data") || mkdir("data")

route(get_frame, "/frame")

route(respond ∘ get_recordings, "/data")

Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]
route("/settings", method = POST) do
    files = Genie.Requests.filespayload()
    for file in files
        txt = String(last(file).data)
        _setups = try2settings(txt)
        if _setups isa String
            @warn _setups
        else
            set_suns(first(_setups).tsuns)
            model.setups[] = _setups
        end
    end
    if length(files) == 0
        @info "No file uploaded"
    end
    return "Upload finished"
end

@app FromFile begin
    @out imageurl = "/frame"

    @in recording_on = false
    @out recording_label = "Not recording"
    @onchange recording_on begin
        set_recording(recording_on)
        recording_label = recording_on ? "Recording" : "Not recording"
    end

    @out interface = "fromfile"


    @in setups = [setup_off]
    @in setups_labels = [setup_off.label]
    @onchange setups setups_labels = getfield.(setups, :label)
    @in chosen = 0
    @onchange chosen set_suns(setups[chosen + 1].tsuns)

    # TODO: fix the following GUI interface:
    @in azimuth = 0.0
    @in link_factor = 0.0
    @in sun_width = 1
    @in red = 0.0
    @in green = 0.0
    @in blue = 0.0
    @onchange azimuth, link_factor, sun_width, red, green, blue begin
        ts = [TrackedSun(deg2rad(azimuth), DancingQueen.Sun(link_factor, sun_width, RGB{N0f8}(red, green, blue)))]
        set_suns(ts)
    end
end myhandlers

ui() = Html.div(
                @on("keydown.a", "chosen=0"), @on("keydown.b", "chosen=1"), @on("keydown.c", "chosen=2"), @on("keydown.d", "chosen=3"), @on("keydown.e", "chosen=4"), @on("keydown.f", "chosen=5"), @on("keydown.g", "chosen=6"), @on("keydown.h", "chosen=7"), @on("keydown.i", "chosen=8"), @on("keydown.j", "chosen=9"), @on("keydown.k", "chosen=10"), @on("keydown.l", "chosen=11"), @on("keydown.m", "chosen=12"), @on("keydown.n", "chosen=13"), @on("keydown.o", "chosen=14"), @on("keydown.p", "chosen=15"), @on("keydown.q", "chosen=16"), @on("keydown.r", "chosen=17"), @on("keydown.s", "chosen=18"), @on("keydown.t", "chosen=19"), @on("keydown.u", "chosen=20"), @on("keydown.v", "chosen=21"), @on("keydown.w", "chosen=22"), @on("keydown.x", "chosen=23"), @on("keydown.y", "chosen=24"), @on("keydown.z", "chosen=25"),
                [
        row([
             h1("DancingQueen")
            ])
        row([
             card(class="st-col col-12", 
                  [
                   row([
                        imageview(src=:imageurl, basic=true, style="max-width: $(h)px")
                       ])
                   row([
                        column(toggle(:recording_label, :recording_on), class = "col-sm st-module")
                        column(btn(class = "q-mt-lg", "Download data", color = "primary", href="data", download=string(round(now(), Second(1)), ".tar")), class = "col-sm st-module")
                     ])

                  ])
            ])
        tabgroup(:interface, 
                 [
                  tab(name="fromfile", label="Setting from file"),
                  tab(name="gui", label="GUI")
                 ])
        tabpanelgroup(:interface,
                      [
                       tabpanel("settings from file", name = "fromfile", [
                                                                 row([
                                                                      uploader(label="Upload settings", multiple=false, accept=".toml", method="POST", url="/settings", hideuploadbtn=false, nothumbnails=true, field__name="csv_file", autoupload=true)
                                                                     ])
                                                                 row([row(@recur("(label, index) in setups_labels"), [radio("tmp", :chosen, val = :index, label=:label)])])
                                                                ])
                       tabpanel("settings from GUI", name = "gui", [

                                                          row([
                                                               h6("Azimuth")
                                                               slider(range(0, 359, step=1.0), :azimuth, markers=true, labelalways=true)
                                                              ])
                                                          row([
                                                               h6("Link factor")
                                                               slider(range(-1, 1, length=21), :link_factor, markers=true, labelalways=true)
                                                              ])
                                                          row([
                                                               h6("Sun color")
                                                               card(class="st-col col-12",
                                                                    [
                                                                     row([
                                                                          cell(size = 1, span("Red"))
                                                                          cell(slider(range(0, 1, 256), :red, markers=true, label=true, color="red"))
                                                                         ])
                                                                     row([
                                                                          cell(size = 1, span("Green"))
                                                                          cell(slider(range(0, 1, 256), :green, markers=true, label=true, color="green"))
                                                                         ])
                                                                     row([
                                                                          cell(size = 1, span("Blue"))
                                                                          cell(slider(range(0, 1, 256), :blue, markers=true, label=true, color="blue"))
                                                                         ])
                                                                    ])
                                                              ])
                                                          row([
                                                               h6("Sun width")
                                                               slider(1:2:nleds, :sun_width, markers=true, label=true)
                                                              ])

                                                                ])
                      ])
       ]
)

global model = init(FromFile, debounce = 0) |> myhandlers

Stipple.js_methods(model::FromFile) = """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""

Stipple.js_created(model::FromFile) = "setInterval(this.updateimage, $(1000 ÷ client_fps))"

route("/") do
    # global model
    page(model, ui) |> html
end

up()

if !isinteractive()
    c = Condition()
    wait(c)
end

