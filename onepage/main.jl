# TODO:
# case insensitive for the keyboard control
#
import Tar
using VideoIO, AprilTags, StaticArrays, ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors
import Colors.N0f8

if !isdir("data")
    mkdir("data")
end

const cam = opencamera()
const img = Ref(read(cam))
const w, h = size(img[])
const nleds = 101

include("detection.jl")
include("leds.jl")
include("logbooks.jl")
include("display.jl")

const beetle = Ref{Union{Nothing, Beetle}}(nothing)
const leds = Ref(get_leds(beetle[]))

dr = DetectoRect()
logbook = LogBook()

task = Threads.@spawn while isopen(cam)
    read!(cam, img[]) # 1/FPS second
    beetle[] = dr(img[]) # 137 μs to 16 ms when naive
    leds[] = get_leds(beetle[]) # 36 ns
    Threads.@spawn log!(logbook, beetle[], leds[]) # sync time 24 ns
end

# ### benchmarks
# function one_round()
#     read!(cam, img[]) # 1/FPS second
#     beetle[] = dr(img[]) # 137 μs to 16 ms when naive
#     leds[] = get_leds(beetle[]) # 36 ns
#     Threads.@spawn log!(logbook, beetle[], leds[]) # sync time 24 ns
# end
# @benchmark one_round() # 100 ms limited by the 10 FPS...
# @benchmark one_round() # 100 ms when naive
#
#
# for i in 1:50
#     read!(cam, img[]) # 1/FPS second
# end
#
# function one_round(img)
#     beetle[] = dr(img[]) # 137 μs to 16 ms when naive
#     leds[] = get_leds(beetle[]) # 36 ns
#     Threads.@spawn log!(logbook, beetle[], leds[]) # sync time 24 ns
# end
# @benchmark one_round(img) # 193 μs
# @benchmark one_round(img) # 16 ms when naive

using GenieFramework
@genietools

# avoid writing to disk
route(get_frame, "/frame")

route("/data") do
    get_data(logbook)
end

@app WebCam begin
    @out imageurl = "/frame"

    @in recording_on = false
    @out recording_label = "Not recording"
    @onchange recording_on begin
        turn!(logbook, recording_on)
        recording_label = recording_on ? "Recording" : "Not recording"
    end

    @in link_facto = 0.0
    @onchange link_facto link_factor[] = link_facto

    @in red = 0.0
    @onchange red sun_color[] = RGB(red, sun_color[].g, sun_color[].b)
    @in green = 0.0
    @onchange green sun_color[] = RGB(sun_color[].r, green, sun_color[].b)
    @in blue = 0.0
    @onchange blue sun_color[] = RGB(sun_color[].r, sun_color[].g, blue)

    @in sun_widt = 1
    @onchange sun_widt sun_width[] = sun_widt

    @out tab_m = "gui"
    @out gpanel = "gui"

    @onchange tab_m begin
        gpanel = tab_m
    end

end myhandlers

ui() = [
        row([
             btn(class = "q-mt-lg", "Download data", color = "primary", href="data", download=string(round(now(), Second(1)), ".tar"))
            ])
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
                        toggle(:recording_label, :recording_on)
                       ])
                  ])
            ])
        tabgroup(:tab_m, [
                          tab(name="gui", icon="sports_esports", label="GUI"),
                          tab(name="file", icon="description", label="File")
                         ])
        tabpanelgroup(:gpanel, 
                      [
                       tabpanel("text???", name = "gui", [
                                                          row([
                                                               h6("Link factor")
                                                               slider(-1:0.1:1, :link_facto, markers=true, labelalways=true)
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
                                                               slider(1:2:nleds, :sun_widt, markers=true, label=true)
                                                              ])
                                                         ]
                               ),
                       tabpanel("also text", name = "file", [
                                                          row([
                                                               h6("Link factor")
                                                               slider(-1:0.1:1, :link_facto, markers=true, labelalways=true)
                                                              ])
                                                            ])
                      ])
       ]

model = init(WebCam, debounce = 0) |> myhandlers

Stipple.js_methods(model::WebCam) = """
    updateimage: async function () { 
        this.imageurl = "frame#" + new Date().getTime()
    }
"""

# Stipple.js_created(model::WebCam) = """
#     setInterval(() => {
#     this.updateimage();
#     }, 33);
# """

# Stipple.js_created(model::WebCam) = """
# (function loop() {
#   setTimeout(() => {
#     () => this.updateimage;
#     loop();
#   }, 100);
# })();
# """

Stipple.js_created(model::WebCam) = "setInterval(this.updateimage, 101)"# $(round(Int, 5*1000/fps)))"

route("/") do
    global model
    page(model, ui) |> html
end

up()
